require 'baidu_pcs'
module BaiduPcs
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
end
