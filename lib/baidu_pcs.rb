require 'typhoeus'
require 'multi_json'
require 'fileutils'
require 'yaml'

require "baidu_pcs/core_ext"
require "baidu_pcs/version"

module BaiduPcs

  PCS_BASE_URL = "https://pcs.baidu.com/rest/2.0/pcs"
  CONFIG_FILE = File.expand_path(ENV['_BAIDU_PCS_CONFIG_FILE']||"~/.baidu_pcs_config.yml")

  class Config
    attr_reader :config
    class << self
      def instance
        @_instance ||= new
      end
      def keys
        instance.config.keys
      end
      def file
        CONFIG_FILE     
      end
      #use like: Config.app_name --> :app_name in config file
      def method_missing(method, *args)
        instance.config[method.to_sym]
      end
    end
   private
    def initialize
      raise "Not found file: #{CONFIG_FILE}, Please run config and setup firstly!" unless File.exists?(CONFIG_FILE)
      @config = YAML.load_file(CONFIG_FILE)
    end
  end

  class Base
    attr_accessor :request, :options, :response, :body

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
          if response.headers["Content-Disposition"] =~ /attachment;file/ or response.headers["Content-Type"] =~ /image\//
            @body = response.body
          else  #default as json
            @body = MultiJson.load(response.body, symbolize_keys: true)
          end
        elsif response.timed_out?
          raise "Timeout with options: #{options}"
        elsif response.code == 0
          raise "Could not get an http response, something's wrong: #{response.return_message} with options: #{options}"
        else
          raise "Http request failed with code: #{response.code}, msg: #{response.body}"
        end
      end
      self
    end

    def run!
      @request.run
      self
    end
    def ok?
      response.success?
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
