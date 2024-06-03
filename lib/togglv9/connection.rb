# frozen_string_literal: true

require 'faraday'
require 'oj'

require_relative '../logging'

module TogglV9
  module Connection
    include Logging

    DELAY_SEC = 1
    MAX_RETRIES = 3

    API_TOKEN = 'api_token'
    TOGGL_FILE = '.toggl'

    def self.open(username = nil, password = API_TOKEN, url = nil, opts = {})
      raise 'Missing URL' if url.nil?

      Faraday.new(url: url, ssl: { verify: true }) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger, Logger.new('faraday.log') if opts[:log]
        faraday.adapter Faraday.default_adapter
        faraday.headers = { 'Content-Type' => 'application/json' }
        faraday.request :authorization, :basic, username, password
      end
    end

    def require_params(params, fields = [])
      raise ArgumentError, 'params is not a Hash' unless params.is_a? Hash
      return if fields.empty?

      errors = []
      fields.each do |f|
        errors.push("params[#{f}] is required") unless params.key?(f)
      end
      raise ArgumentError, errors.join(', ') unless errors.empty?
    end

    def _call_api(procs)
      # logger.debug(procs[:debug_output].call)
      full_resp = nil
      i = 0
      loop do
        i += 1
        full_resp = procs[:api_call].call
        # logger.ap(full_resp.env, :debug)
        break if full_resp.status != 429 || i >= MAX_RETRIES

        sleep(DELAY_SEC)
      end

      raise full_resp.headers['warning'] if full_resp.headers['warning']
      raise "HTTP Status: #{full_resp.status}" unless full_resp.success?
      return {} if full_resp.body.nil? || full_resp.body == 'null'

      full_resp
    end

    def get(resource, params = {})
      query_params = params.map { |k, v| "#{k}=#{v}" }.join('&')
      resource += "?#{query_params}" unless query_params.empty?
      resource_encoded = resource.gsub('+', '%2B')
      full_resp = _call_api(debug_output: -> { "GET #{resource_encoded}" },
                            api_call: -> { conn.get(resource_encoded) })
      return {} if full_resp == {}

      begin
        resp = Oj.load(full_resp.body)
        return resp['data'] if resp.respond_to?(:has_key?) && resp.key?('data')

        resp
      rescue Oj::ParseError
        full_resp.body
      end
    end

    def post(resource, data = '', json_response: true)
      resource_encoded = resource.gsub('+', '%2B')
      full_resp = _call_api(debug_output: -> { "POST #{resource_encoded} / #{data}" },
                            api_call: -> { conn.post(resource_encoded, Oj.dump(data)) })
      return {} if full_resp == {}
      return Oj.load(full_resp.body) if json_response

      full_resp.body
    end

    def put(resource, data = '')
      resource_encoded = resource.gsub('+', '%2B')
      full_resp = _call_api(debug_output: -> { "PUT #{resource_encoded} / #{data}" },
                            api_call: -> { conn.put(resource_encoded, Oj.dump(data)) })
      return {} if full_resp == {}

      Oj.load(full_resp.body)
    end

    def patch(resource, data = '')
      resource_encoded = resource.gsub('+', '%2B')
      full_resp = _call_api(debug_output: -> { "PATCH #{resource_encoded} / #{data}" },
                            api_call: -> { conn.patch(resource_encoded, Oj.dump(data)) })
      return {} if full_resp == {}

      Oj.load(full_resp.body)
    end

    def delete(resource)
      resource_encoded = resource.gsub('+', '%2B')
      full_resp = _call_api(debug_output: -> { "DELETE #{resource_encoded}" },
                            api_call: -> { conn.delete(resource_encoded) })
      return {} if full_resp == {}

      full_resp.body
    end
  end
end
