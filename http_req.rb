# frozen_string_literal: true

require 'faraday'

module HttpApi
  class << self
    def get_request(url)
      url = URI(url) unless url.is_a? URI
      resp = connection(url).get(url) do |req|
        req.headers['Accept'] = 'application/json'
        req.headers['Authorization'] = auth_header
      end
      resp.body
    end

    def get_json(url)
      JSON.parse(get_request(url))
    end

    def post_request(url, body)
      url = URI(url) unless url.is_a? URI
      resp = connection(url).post(url) do |req|
        req.headers['Accept'] = 'application/json'
        req.headers['Authorization'] = auth_header
        req.headers['Content-Type'] = 'application/json'
        req.body = body.to_json
      end
      resp.body
    end

    def post_json(url, body)
      JSON.parse(post_request(url, body))
    end

    def auth_header
      "Bearer #{ENV['ACCESS_TOKEN']}"
    end

    def connection(url)
      Faraday.new(url: url) do |faraday|
        faraday.use Faraday::Response::RaiseError
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
