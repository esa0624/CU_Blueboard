require 'net/http'
require 'json'

module ContentSafety
  # OpenAI Moderation API client for basic content flagging
  # Currently returns only flagged status; detailed category analysis deferred
  class OpenaiClient
    API_URL = 'https://api.openai.com/v1/moderations'.freeze
    MODEL = 'omni-moderation-latest'.freeze

    class Error < StandardError; end
    class MissingApiKeyError < Error; end

    def initialize
      @api_key = ENV['OPENAI_API_KEY']
      raise MissingApiKeyError, 'OPENAI_API_KEY environment variable is required' if @api_key.nil? || @api_key.empty?
    end

    # Screen text content for policy violations
    # @param text [String] The text to screen
    # @return [Hash] { flagged: Boolean, categories: Hash, category_scores: Hash }
    # @raise [Error] if API request fails
    def screen(text:)
      uri = URI(API_URL)
      request = build_request(uri, text)
      response = execute_request(uri, request)

      parse_response(response)
    rescue StandardError => e
      Rails.logger.error("OpenAI Moderation API error: #{e.message}")
      raise Error, "Failed to screen content: #{e.message}"
    end

    private

    def build_request(uri, text)
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"
      request['Content-Type'] = 'application/json'
      request.body = {
        model: MODEL,
        input: text
      }.to_json
      request
    end

    def execute_request(uri, request)
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true
      # Relax SSL verification in development (macOS certificate issues)
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development? || Rails.env.test?
      http.request(request)
    end

    def parse_response(response)
      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "API returned #{response.code}: #{response.body}"
      end

      data = JSON.parse(response.body)
      result = data.dig('results', 0)

      unless result
        raise Error, "Unexpected API response format: #{data}"
      end

      {
        flagged: result['flagged'] || false,
        categories: result['categories'] || {},
        category_scores: result['category_scores'] || {}
      }
    end
  end
end
