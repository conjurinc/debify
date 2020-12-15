
When /^I get help for "([^"]*)"$/ do |app_name|
  @app_name = app_name
  step %(I run `#{app_name} help`)
end

# Add more step definitions here

When /^I start a container named "(.*?)"(?: on network "(.*?)")*$/ do |name, net_name|
  step %Q{I successfully run `docker run -d --name='#{name}' --network='#{net_name}' alpine sh -c 'while true; do sleep 1; done'`}
  containers << Docker::Container.get(name)
end

When /^I successfully start a sandbox for "(.*?)" with arguments "(.*?)"$/ do |project, args|
  step %Q{I successfully run `env DEBUG=true GLI_DEBUG=true debify sandbox -d ../../#{project} #{args}`}
  containers << Docker::Container.get("#{project}-sandbox")
end
