####################################################################################
#              File Apis
#http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list

require "baidu_pcs"
module BaiduPcs
  class Fs < Base

    FILE_BASE_URL = "#{PCS_BASE_URL}/file"

    #path:  local file path
    #rpath: 上传文件路径（含上传的文件名称)
    def self.upload(path, rpath=nil, opts={})
      params = method_params(:upload, path: "#{Config.app_root}/#{rpath||File.basename(path)}")
      params[:ondup] = opts.delete(:ondup) if opts[:ondup]
      post(FILE_BASE_URL, params, {file: File.open(path)}, opts)
    end

    def self.download(rpath, opts={})
      params = method_params(:download, path: "#{Config.app_root}/#{rpath}") 
      get(FILE_BASE_URL, params, opts)
    end

    #流式资源地址，可直接下载
    def self.streamurl(rpath)
      params = method_params(:download, path: "#{Config.app_root}/#{rpath}")
      query_str = params.map{|k, v| "#{k}=#{v}"}.join("&") #可能有些转义问题
      "#{FILE_BASE_URL}?#{query_str}"
    end

    def self.mkdir(rpath)
      post(FILE_BASE_URL, method_params(:mkdir, path: "#{Config.app_root}/#{rpath}"))
    end

    def self.meta(rpath)
      get(FILE_BASE_URL, method_params(:meta, path: "#{Config.app_root}/#{rpath}"))
    end

    def self.list(rpath=nil, opts={})
      params = method_params(:list, path: "#{Config.app_root}/#{rpath}").merge(opts)
      get(FILE_BASE_URL, params)
    end

    def self.move(from_rpath, to_rpath)
      params = method_params(:move, 
                             from: "#{Config.app_root}/#{from_rpath}",
                             to: "#{Config.app_root}/#{to_rpath}")
      post(FILE_BASE_URL, params)
    end

    def self.copy(from_rpath, to_rpath)
      params = method_params(:copy, 
                             from: "#{Config.app_root}/#{from_rpath}",
                             to: "#{Config.app_root}/#{to_rpath}")
      post(FILE_BASE_URL, params)
    end

    #文件/目录删除后默认临时存放在回收站内;10天后永久删除
    def self.delete(rpath)
      params = method_params(:delete, path: "#{Config.app_root}/#{rpath}")
      post(FILE_BASE_URL, params) 
    end

    def self.search(keyword, rpath, opts = {})
      params = method_params(:search, 
                             wd: keyword,
                             path: "#{Config.app_root}/#{rpath}")
      params[:re] = opts[:recursive] ? '1' : '0'
      get(FILE_BASE_URL, params) 
    end
  end
end
