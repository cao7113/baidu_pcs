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

    #return 
    # md5 to store at local
    def self.uploadslice(path, opts={})
      params = method_params(:upload, type: :tmpfile)
      post(FILE_BASE_URL, params, {file: File.open(path)}, opts)
    end
    #分片上传—合并分片文件
    def self.createsuperfile(rpath, opts={})
      params = method_params(:createsuperfile, 
                             path: "#{Config.app_root}/#{rpath}")
      params[:ondup] = opts.delete(:ondup) if opts.key?(:ondup)
      post(FILE_BASE_URL, params, {param: opts.delete(:param)}, opts)
    end

    def self.download(rpath, opts={})
      params = method_params(:download, path: "#{Config.app_root}/#{rpath}") 
      get(FILE_BASE_URL, params, opts.merge(followlocation: true))
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
    def self.meta_in_batch(param)
      post(FILE_BASE_URL, method_params(:meta), {param: param})
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
    def self.move_in_batch(param)
      post(FILE_BASE_URL, method_params(:move), {param: param})
    end

    def self.copy(from_rpath, to_rpath)
      params = method_params(:copy, 
                             from: "#{Config.app_root}/#{from_rpath}",
                             to: "#{Config.app_root}/#{to_rpath}")
      post(FILE_BASE_URL, params)
    end
    def self.copy_in_batch(param)
      post(FILE_BASE_URL, method_params(:copy), {param: param})
    end

    #文件/目录删除后默认临时存放在回收站内;10天后永久删除
    def self.delete(rpath)
      params = method_params(:delete, path: "#{Config.app_root}/#{rpath}")
      post(FILE_BASE_URL, params) 
    end
    def self.delete_in_batch(param)
      post(FILE_BASE_URL, method_params(:delete), {param: param})
    end

    def self.search(keyword, rpath, opts = {})
      params = method_params(:search, 
                             wd: keyword,
                             path: "#{Config.app_root}/#{rpath}")
      params[:re] = opts[:recursive] ? '1' : '0'
      get(FILE_BASE_URL, params) 
    end

    ###############################################################
    #             Advanced
    #获取指定图片文件的缩略图
    def self.thumnail(rpath, opts={})
      params = method_params(:generate, path: "#{Config.app_root}/rpath").merge(opts.slice!(:quality, :height, :width))
      get("#{PCS_BASE_URL}/thumbnail", params, opts)
    end
    
    #文件增量更新操作查询接口。本接口有数秒延迟，但保证返回结果为最终一致。
    def self.diff(cursor)
      get(FILE_BASE_URL, method_params(:diff, cursor: cursor)) 
    end

    #视频转码 TODO

    #以视频、音频、图片及文档四种类型的视图获取所创建应用程序下的文件列表
    def self.list_by_type(type, opts={})
      params = method_params(:list, type: type).merge(opts.slice!(:start, :limit, :filter_path))
      get("#{PCS_BASE_URL}/stream", params, opts)
    end

    #秒传和回收站 TODO
  end
end
