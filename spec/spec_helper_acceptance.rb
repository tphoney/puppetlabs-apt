require 'beaker-pe'
require 'beaker-puppet'
require 'beaker-rspec'
require 'beaker/puppet_install_helper'
require 'beaker/module_install_helper'
require 'beaker-task_helper'

run_puppet_install_helper
install_bolt_on(hosts) unless pe_install?
install_module_on(hosts)
install_module_dependencies_on(hosts)
configure_type_defaults_on(hosts)

UNSUPPORTED_PLATFORMS = ['RedHat', 'Suse', 'windows', 'AIX', 'Solaris'].freeze
MAX_RETRY_COUNT       = 12
RETRY_WAIT            = 10
ERROR_MATCHER         = %r{(no valid OpenPGP data found|keyserver timed out|keyserver receive failed)}

# This method allows a block to be passed in and if an exception is raised
# that matches the 'error_matcher' matcher, the block will wait a set number
# of seconds before retrying.
# Params:
# - max_retry_count - Max number of retries
# - retry_wait_interval_secs - Number of seconds to wait before retry
# - error_matcher - Matcher which the exception raised must match to allow retry
# Example Usage:
# retry_on_error_matching(3, 5, /OpenGPG Error/) do
#   apply_manifest(pp, :catch_failures => true)
# end
def retry_on_error_matching(max_retry_count = MAX_RETRY_COUNT, retry_wait_interval_secs = RETRY_WAIT, error_matcher = ERROR_MATCHER)
  try = 0
  begin
    puts "retry_on_error_matching: try #{try}" unless try.zero?
    try += 1
    yield
  rescue StandardError => e
    raise unless try < max_retry_count && (error_matcher.nil? || e.message =~ error_matcher)
    sleep retry_wait_interval_secs
    retry
  end
end

RSpec.configure do |c|
  File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    run_puppet_access_login(user: 'admin') if pe_install? && puppet_version =~ %r{(5\.\d\.\d)}
  end
end
