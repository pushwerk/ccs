require 'net/https'
require 'oj'
require 'uri'

module CCS
  class HTTPWorker
    include Celluloid

    def query(message)
      path = path_for_operation(message.operation)
      return if path.nil?
      uri = URI.parse("https://android.googleapis.com/gcm#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.post(uri.path, message.to_json, header)
      CCS.debug "Response #{response.code} #{response.message}: #{response.body}"
      case response.code
      when '200'
        case (path)
        when '/notification'
          return Oj.load(response.body)['notification_key']
        end
      when '401'
        CCS.error('HTTP Error: Authentication error')
      else
        CCS.error("HTTP Error #{response.code}: #{response.body}")
      end
      nil
    end

    private

    def path_for_operation(operation)
      case operation
      when 'add', 'remove', 'create'
        '/notification'
      end
    end

    def header
      {
        'Authorization' => "key=#{CCS.configuration.api_key}",
        'project_id'    => CCS.configuration.sender_id,
        'Content-Type'  => 'application/json'
      }
    end
  end
end
