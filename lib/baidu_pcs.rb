require 'typhoeus'
require 'multi_json'
require 'fileutils'
require 'yaml'

require "baidu_pcs/core_ext"
require "baidu_pcs/version"
require "baidu_pcs/config"

module BaiduPcs
  PCS_BASE_URL = "https://pcs.baidu.com/rest/2.0/pcs"

  #code: 404, msg: {"error_code":31066,"error_msg":"file does not exist","request_id":4043575136}
  class PcsError < StandardError; end
  class PcsRequestError < PcsError
    attr_accessor :json_str, :hash, :http_code
    def initialize(http_code, json_str)
      @http_code = http_code
      @json_str = json_str
      @hash = MultiJson.load(json_str, symbolize_keys: true) rescue nil
    end

    def method_missing(method, *args)
      hash[method.to_sym]
    end

    def to_s
      "http code: #{http_code}, with info: #{hash.to_s}"
    end
  end

  class Base
    attr_accessor :request, :options, :response, :body, :error

    def initialize(url, method=:get, params={}, body={}, opts={})
      [:noprogress, :verbose].each do |k|
        opts[k] = params.delete(k) if params.key?(k) and !opts.key?(k)
      end
      @options = {
        method: method||:get,
        headers: {"User-Agent"=>"Mozilla/5.0 (X11; Linux x86_64; rv:2.0.1) Gecko/20100101 Firefox/4.0.1"},
        params: params
      } 
      if headers = opts.delete(:headers) 
        @options[:headers].merge!(headers)
      end
      @options.merge!(body: body) unless body.blank?
      @options.merge!(opts)
      @request = Typhoeus::Request.new(url, @options)
      if @options[:verbose]
        puts "#### request options: "
        puts @options
      end
      @request.on_complete do |response|
        @response = response
        if response.success? #(mock || return_code == :ok) && response_code && response_code >= 200 && response_code < 300
          #for download
          if response.headers["Content-Disposition"] =~ /attachment;file/ or response.headers["Content-Type"] =~ /image\//
            @body = response.body
          else  #default as json for general request
            @body = MultiJson.load(response.body, symbolize_keys: true)
          end
        elsif response.timed_out?
          raise "Timeout with options: #{options}"
        elsif response.code == 0
          raise "Could not get an http response, something's wrong: #{response.return_message} with options: #{options}"
        else
          @error = PcsRequestError.new(response.code, response.body)
        end
      end
      self
    end

    def run!
      @request.run
      raise error if has_error?
      self
    end
    def ok?
      response.success?
    end
    def has_error?
      !!error
    end
    def http_code
      response.code
    end

    class << self
      def get(url, params={}, opts={})
        new(url, :get, params, nil, opts).run!
      end
      def post(url, params={}, body={}, opts={})
        new(url, :post, params, body, opts).run!
      end
      def put(url, params={}, body={}, opts={})
        new(url, :put, params, body, opts).run!
      end
      def delete(url, params={}, opts={})
        new(url, :delete, params, opts).run!
      end

      #common
      def atoken_params
        {access_token: Config.access_token}
      end
      def method_params(buz_method=nil, params={})
        opts = atoken_params.merge(params)
        opts.merge!(method: buz_method) if buz_method
        opts
      end
      def quota
        get("#{PCS_BASE_URL}/quota", method_params(:info))
      end
    end
  end
end
