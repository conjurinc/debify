require 'netrc'
Netrc.configure do |c|
  c[:allow_permissive_netrc_file] = true
end

if File.exist?('/root/.netrc') && ENV['CONJUR_APPLIANCE_URL']
  creds = Netrc.read('/root/.netrc')[ENV['CONJUR_APPLIANCE_URL'] + '/authn'] 
  print "#{creds.login} #{creds.password}" if creds
end
