require "net/http"
require "json"

class InternalApiClient
  class ServiceUnavailable < StandardError; end
  class ConnectionNotFound < StandardError; end

  class << self
    def start_connection(server_id:, user_id:, config:)
      post(irc_service_url("/internal/irc/connections"), {
        server_id: server_id,
        user_id: user_id,
        config: config
      })
    end

    def stop_connection(server_id:)
      delete(irc_service_url("/internal/irc/connections/#{server_id}"))
    end

    def send_command(server_id:, command:, params:)
      response = post(irc_service_url("/internal/irc/commands"), {
        server_id: server_id,
        command: command,
        params: params
      })

      case response.code.to_i
      when 202 then true
      when 404 then raise ConnectionNotFound, "Server #{server_id} not connected"
      else raise ServiceUnavailable, "IRC service error: #{response.code}"
      end
    end

    def post_event(server_id:, user_id:, event:)
      post(web_service_url("/internal/irc/events"), {
        server_id: server_id,
        user_id: user_id,
        event: event
      })
    end

    def status
      get(irc_service_url("/internal/irc/status"))
    end

    def ison(server_id:, nicks:)
      query = URI.encode_www_form(server_id: server_id, nicks: nicks)
      response = get(irc_service_url("/internal/irc/ison?#{query}"))

      case response.code.to_i
      when 200
        JSON.parse(response.body)["online"]
      when 404
        nil
      else
        raise ServiceUnavailable, "IRC service error: #{response.code}"
      end
    end

    private

    def irc_service_url(path)
      Rails.configuration.irc_service_url + path
    end

    def web_service_url(path)
      Rails.configuration.web_service_url + path
    end

    def post(url, body)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Post.new(uri.path)
      request["Authorization"] = "Bearer #{secret}"
      request["Content-Type"] = "application/json"
      request.body = body.to_json

      http.request(request)
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Net::OpenTimeout, Net::ReadTimeout => e
      raise ServiceUnavailable, "Service unreachable: #{e.message}"
    end

    def get(url)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Get.new(uri.request_uri)
      request["Authorization"] = "Bearer #{secret}"

      http.request(request)
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Net::OpenTimeout, Net::ReadTimeout => e
      raise ServiceUnavailable, "Service unreachable: #{e.message}"
    end

    def delete(url)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"

      request = Net::HTTP::Delete.new(uri.path)
      request["Authorization"] = "Bearer #{secret}"

      http.request(request)
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, Net::OpenTimeout, Net::ReadTimeout => e
      raise ServiceUnavailable, "Service unreachable: #{e.message}"
    end

    def secret
      ENV.fetch("INTERNAL_API_SECRET")
    end
  end
end
