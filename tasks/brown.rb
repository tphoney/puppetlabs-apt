#!/opt/puppetlabs/puppet/bin/ruby
require 'json'
require 'open3'
require 'puppet'

def local_key(type, name)
  [type, name].join('/')
end

def get_resource(type, name = nil)
  key = local_key(type, name)
  Puppet.settings.initialize_app_defaults(Puppet::Settings.app_defaults_for_run_mode(Puppet::Util::RunMode[:user]))
  Puppet::ApplicationSupport.push_application_context(Puppet::Util::RunMode[:user])
  Puppet.lookup(:current_environment)
  resources = if name.nil?
                Puppet::Resource.indirection.search(key, {})
              else
                [Puppet::Resource.indirection.find(key)]
              end
  text = ''
  resources.each do |resource|
    text = text + resource.prune_parameters(parameters_to_include: @extra_params).to_manifest.force_encoding(Encoding.default_external) + "\n"
  end
  text
end

params = JSON.parse(STDIN.read)
action = params['action'] unless params['action'].nil?

begin
  result = get_resource('file', '/etc/passwd')
  puts result
  result = get_resource('user')
  puts result
  result = get_resource('apt_key')
  puts result
  exit 0
rescue Puppet::Error => e
  puts({ status: 'failure', error: e.message }.to_json)
  exit 1
end
