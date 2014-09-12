module AppnexusApi
  module Faraday
    module Request
      class Logger < ::Faraday::Middleware
        def call(env)
          @app.call(env).on_complete do
            STDERR.puts "============== debug_log =============="
            STDERR.puts env.inspect
            STDERR.puts "============= / debug_log ============="
          end
        end
      end
    end
  end
end
