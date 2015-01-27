module AppnexusApi
  module Faraday
    module Request
      class Logger < ::Faraday::Middleware
        def call(env)
          @app.call(env).on_complete do |response_env|
            STDERR.puts "============== debug_log =============="
            STDERR.puts response_env.inspect
            STDERR.puts "============= / debug_log ============="
          end
        end
      end
    end
  end
end
