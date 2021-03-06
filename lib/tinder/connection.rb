require 'httparty'
require 'active_support/core_ext/hash/indifferent_access'

# override HTTParty's json parser to return a HashWithIndifferentAccess
module HTTParty
  class Parser
    protected
    def json
      result = Crack::JSON.parse(body)
      if result.is_a?(Hash)
        result = HashWithIndifferentAccess.new(result)
      end
      result
    end
  end
end

module Tinder
  class Connection
    HOST = "campfirenow.com"

    attr_reader :subdomain, :uri, :options

    def initialize(subdomain, options = {})
      @subdomain = subdomain
      @options = { :ssl => false, :proxy => ENV['HTTP_PROXY'] }.merge(options)
      @uri = URI.parse("#{@options[:ssl] ? 'https' : 'http' }://#{subdomain}.#{HOST}")
      @token = options[:token]


      class << self
        include HTTParty
        extend HTTPartyExtensions

        headers 'Content-Type' => 'application/json'
      end

      if @options[:proxy]
        proxy_uri = URI.parse(@options[:proxy])
        http_proxy proxy_uri.host, proxy_uri.port
      end
      base_uri @uri.to_s
      basic_auth token, 'X'

      # auto-detect ssl if not specified
      # try to request ssl, and if we're redirected to http, we know ssl is not enabled
      unless options.has_key?(:ssl)
        ssl_base_uri = @uri
        ssl_base_uri.scheme = 'https'
        begin
          response = get(ssl_base_uri.to_s + '/users/me', :no_follow => true)
          @uri = ssl_base_uri
          base_uri @uri.to_s
          @options[:ssl] = true
        rescue HTTParty::RedirectionTooDeep; end # redirected, so stick with http
      end
    end

    module HTTPartyExtensions
      def perform_request(http_method, path, options) #:nodoc:
        response = super
        raise AuthenticationFailed if response.code == 401
        response
      end
    end

    def token
      @token ||= begin
        self.basic_auth(options[:username], options[:password])
        self.get('/users/me.json')['user']['api_auth_token']
      end
    end

    def metaclass
      class << self; self; end
    end

    def method_missing(*args, &block)
      metaclass.send(*args, &block)
    end

    # Is the connection to campfire using ssl?
    def ssl?
      uri.scheme == 'https'
    end

  end
end
