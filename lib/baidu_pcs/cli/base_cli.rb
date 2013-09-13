require 'baidu_pcs'
require 'thor'
require 'baidu_pcs/cli/thor_ext'
module BaiduPcs::Cli
  class BaseCli < Thor
    include Thor::Actions

    class_option :noprogress, type: :boolean, default: false, desc: "display CURL progress-bar when interacting with remote resources"
    class_option :verbose, type: :boolean, default: false, desc: "display verbose info for tracking"

    desc 'setup APP_NAME, API_KEY, SECRET_KEY [, LOCAL_APP_ROOT]', 'setup app settings'
    def setup(app_name, api_key, secret_key, local_app_root=nil)
      local_app_root ||= File.expand_path("~/baidu/#{app_name}")
      require 'erb'
      content = (ERB.new <<-EOF).result(binding)
:app_name: <%=app_name||'<_app_name>'%>
:app_root: /apps/<%=app_name||'<_app_name_or_you_set_in_baidu>'%>
:api_key: <%=api_key||'<_api_key>'%>
:secret_key: <%=secret_key||'<_secret_key>'%>
:local_app_root: <%=local_app_root||'<_loal_app_root>'%>
      EOF
      config_path = BaiduPcs::CONFIG_FILE
      File.write(config_path, content)
      say "Has wrote #{config_path} for app settings."
    end

    desc 'config', 'config your access token'
    def config
      url = "https://openapi.baidu.com/oauth/2.0/authorize?response_type=token&client_id=#{BaiduPcs::Config.api_key}&redirect_uri=oob&scope=netdisk"
      #res = BaiduPcs::Base.get(url, nil, followlocation: true) #
      #页面可能有要执行的js代码和要用户授权操作, 不能完全程序自动执行
      say "请在浏览器中完成授权操作并获取最终成功url！"
      if system("which xdg-open")
        cmd = "xdg-open '#{url}'"
        say "running command: #{cmd}"
        `#{cmd}`
      else
        say "将下面的链接粘入浏览器获取access_token"
        say url
      end
      say "将浏览器的url输入到这里：" 
      atoken = STDIN.gets.chomp
      atoken =~ /access_token=([^&]*)/
      atoken = $1 if $1
      raise "Invalid token: #{atoken}!" if atoken !~ /^[\da-f\.\-]*$/
      File.open(BaiduPcs::CONFIG_FILE, "a"){|f| f.puts ":access_token: #{atoken}" }
      say "Have append access token into file: #{BaiduPcs::CONFIG_FILE}"
    end

    desc 'quota', 'quota space for storage'
    def quota
      say BaiduPcs::Base.quota.body
    end
  end
end
