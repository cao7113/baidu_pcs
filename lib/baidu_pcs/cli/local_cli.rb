require 'baidu_pcs/cli/base_cli'
module BaiduPcs::Cli
  class LocalCli < BaseCli
    desc 'home', 'display local app root'
    def home
      say BaiduPcs::Config.local_app_root
    end

    desc 'list [PATH]', 'list local app path'
    def list(path=nil)
      say `ls -l #{BaiduPcs::Config.local_app_root}/#{path}`
    end
  end
end
