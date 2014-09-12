require 'appnexusapi'
require 'debugger'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end

def apnx_connection
  return @connection if @connection

  begin
    config_path = File.dirname(__FILE__) + "/appnexus_credentials.yaml"
    @config = YAML.load_file(config_path)
  rescue Errno::ENOENT
    message = "Specs can't run until you configure the AppnexusApi::Connection:\n"
    message += "mv #{config_path}-template #{config_path}"
    raise $!, message
  end

  @connection = AppnexusApi::Connection.new(@config)
end