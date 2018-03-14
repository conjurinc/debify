
When /^I get help for "([^"]*)"$/ do |app_name|
  @app_name = app_name
  step %(I run `#{app_name} help`)
end

# Add more step definitions here

When /^I start a container named "(.*?)"(?: on network "(.*?)")*$/ do |name, net_name|
  if net_name
    network =  Docker::Network.create(net_name)
    networks << network
  end
  
  alpine = Docker::Image.create('fromImage' => 'alpine')
  options = {
    'name' => name,
    'Cmd' => [ "sh", "-c", "while true; do sleep 1; done" ],
    'Image' => alpine.id
  }
  options['HostConfig'] = { 'NetworkMode' => net_name } if net_name
    
  container = Docker::Container.create(options)
  container.start!
  containers << container
end

When /^I successfully start a sandbox for "(.*?)" with arguments "(.*?)"$/ do |project, args|
  step %Q{I successfully run `env DEBUG=true GLI_DEBUG=true debify sandbox -d ../../#{project} #{args}`}
  containers << Docker::Container.get("#{project}-sandbox")
end
