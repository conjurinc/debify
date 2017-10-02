require 'netrc'
Netrc.configure do |c|
  c[:allow_permissive_netrc_file] = true
end

creds = Netrc.read('/root/.netrc')[ENV['CONJUR_APPLIANCE_URL'] + '/authn']
print "#{creds.login} #{creds.password}"
