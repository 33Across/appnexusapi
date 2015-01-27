require 'appnexusapi/faraday/encode_json'
require 'appnexusapi/faraday/parse_json'
require 'appnexusapi/faraday/raise_http_error'
require 'appnexusapi/faraday/logger'
require "faraday_middleware"

class AppnexusApi::Connection
  def initialize(config)
    config["uri"] = "http://api.adnxs.com/" unless config.has_key?("uri")
    debug_log = config.delete("debug_log")
    @config = config
    @connection = Faraday::Connection.new(:url => config["uri"]) do |faraday|
      faraday.request :json
      faraday.use AppnexusApi::Faraday::Response::RaiseHttpError
      faraday.use AppnexusApi::Faraday::Response::ParseJsonBody
      faraday.response :json, :content_type => /\bjson$/

      if debug_log
        faraday.use AppnexusApi::Faraday::Request::Logger
        # faraday.use Faraday::Response::Logger
      end

      faraday.adapter Faraday.default_adapter
    end
  end

  def is_authorized?
    !@token.nil?
  end

  def login
    response = @connection.run_request(:post, 'auth', { "auth" => { "username" => @config["username"], "password" => @config["password"] } }, {})
    @token = response.body["token"]
  end

  def logout
    @token = nil
  end

  def get(route, params={}, headers={})
    params = params.delete_if {|key, value| value.nil? }
    run_request(:get, @connection.build_url(route, params), nil, headers).body
  end

  def build_url(route, params)
    @connection.build_url(route, params)
  end

  def post(route, body=nil, headers={})
    run_request(:post, route, body, headers).body
  end

  def put(route, body=nil, headers={})
    run_request(:put, route, body, headers).body
  end

  def delete(route, body=nil, headers={})
    run_request(:delete, route, body, headers).body
  end

  def run_request(method, route, body, headers)
    login if !is_authorized?
    begin
      @connection.run_request(method, route, body, { "Authorization" => @token }.merge(headers))
    rescue AppnexusApi::Unauthorized => e
      if @retry == true
        raise AppnexusApi::Unauthorized, e
      else
        @retry = true
        logout
        run_request(method, route, body, headers)
      end
    rescue Faraday::Error::TimeoutError => e
      raise AppnexusApi::Timeout, "Timeout"
    ensure
      @retry = false
    end
  end
end
