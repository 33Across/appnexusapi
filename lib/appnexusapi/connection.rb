require 'faraday_middleware'
require 'appnexusapi/faraday/raise_http_error'

class AppnexusApi::Connection
  # Inexplicably, sandbox uses the correct code of 429, while production uses 405? so
  # we just rely on the error message
  RATE_EXCEEDED_ERROR = 'RATE_EXCEEDED'.freeze
  RATE_EXCEEDED_DEFAULT_TIMEOUT = 15

  attr_reader :logger

  def initialize(config)
    @config = config
    @config['uri'] ||= 'https://api.appnexus.com/'
    @logger = @config['logger'] || Logger.new(STDOUT)
    @connection = Faraday.new(@config['uri']) do |conn|
      conn.response :logger, @logger, bodies: true
      conn.request :json
      conn.response :json, :content_type => /\bjson$/

      conn.use AppnexusApi::Faraday::Response::RaiseHttpError
      conn.adapter Faraday.default_adapter
    end
  end

  def is_authorized?
    !@token.nil?
  end

  def login
    response = @connection.run_request(:post, 'auth', { 'auth' => { 'username' => @config['username'], 'password' => @config['password'] } }, {})
    if response.body['response']['error_code']
      fail "#{response.body['response']['error_code']}/#{response.body['response']['error_description']}"
    end

    @token = response.body['response']['token']
  end

  def logout
    @token = nil
  end

  def get(route, params={}, headers={})
    params = params.delete_if { |_, v| v.nil? }
    run_request(:get, build_url(route, params), nil, headers)
  end

  def build_url(route, params)
    @connection.build_url(route, params)
  end

  def post(route, body=nil, headers={})
    run_request(:post, route, body, headers)
  end

  def put(route, body=nil, headers={})
    run_request(:put, route, body, headers)
  end

  def delete(route, body=nil, headers={})
    run_request(:delete, route, body, headers)
  end

  def run_request(method, route, body, headers)
    login unless is_authorized?
    response = {}

    begin
      loop do
        response = run_request_only(
          method,
          route,
          body,
          { 'Authorization' => @token }.merge(headers)
        )
        break if response.body.empty? # Log level data download service returns a body of ""
        break unless response.body.fetch('response', {})['error_code'] == RATE_EXCEEDED_ERROR
        wait_time = response.headers['retry-after'] || RATE_EXCEEDED_DEFAULT_TIMEOUT
        log.info("received rate exceeded.  wait time: #{wait_time}s")
        sleep wait_time.to_i
      end
    rescue AppnexusApi::Unauthorized
      if @retry == true
        raise
      else
        @retry = true
        logout
        response = run_request(method, route, body, headers)
      end
    rescue Faraday::Error::TimeoutError
      raise AppnexusApi::Timeout, 'Timeout'
    ensure
      @retry = false
    end

    response
  end

  def run_request_only(method, route, body, headers)
    @connection.run_request(
      method,
      route,
      body,
      { 'Authorization' => @token }.merge(headers)
    )
  end
end
