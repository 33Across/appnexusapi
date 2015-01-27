module AppnexusApi
  module Faraday
    module Response
      class ParseJsonBody < ::Faraday::Middleware

        def call(request_env)
          @app.call(request_env).on_complete do |response_env|
            response_env[:body] = (response_env[:body])["response"]
            check_for_error(response_env)
          end
        end

        protected

        def convert_to_json(body)
          case body.strip
          when ''
            nil
          when 'true'
            true
          when 'false'
            false
          else
            begin
              ::MultiJson.decode(body)
            rescue Exception => exception
              raise AppnexusApi::InvalidJson
            end
          end
        end

        def check_for_error(env)
          if env[:body].has_key?("error")
            case env[:body]["error_id"]
            when "NOAUTH"
              raise AppnexusApi::Unauthorized, error_message(env)
            when "UNAUTH"
              raise AppnexusApi::Forbidden, error_message(env)
            when "SYNTAX"
              raise AppnexusApi::UnprocessableEntity, error_message(env)
            when "SYSTEM"
              raise AppnexusApi::InternalServerError, error_message(env)
            when "INTEGRITY"
              raise AppnexusApi::UnprocessableEntity, error_message(env)
            else
              raise AppnexusApi::Error, error_message(env)
            end
          end
        end

        def error_message(env)
          "#{env[:method].to_s.upcase} #{env[:url].to_s} (#{env[:body]["error_id"]}): #{env[:body]["error"]}"
        end

      end
    end
  end
end
