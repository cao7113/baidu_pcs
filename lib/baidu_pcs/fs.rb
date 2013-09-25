####################################################################################
#              File Apis
#http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/file_data_apis_list

require "baidu_pcs"
require "digest"

module BaiduPcs

  #cao@tj-desktop:~/dev/baidu_pcs$ be bin/baidupcs meta
  #{:fs_id=>1340895656, :path=>"/apps/uasset", :ctime=>1378535715, :mtime=>1378535715, :block_list=>"", :size=>0, :isdir=>1, :ifhassubdir=>1, :filenum=>0}
  #cao@tj-desktop:~/dev/baidu_pcs$ be bin/baidupcs meta Gemfile
  #{:fs_id=>2730525873, :path=>"/apps/uasset/Gemfile", :ctime=>1378888179, :mtime=>1378888179, :block_list=>"[\"4bec0132b488fde4d0806cd654be3b2e\"]", :size=>127, :isdir=>0, :ifhassubdir=>0, :filenum=>0}
  class FileMeta
    attr_accessor :origin_hash, :_mate
    def initialize(hash)
      raise "Invalid hash for file meta" if hash.blank?
      @origin_hash = hash
      #temp fix json parse FIXME
      if block_list.is_a?(String) and block_list.length > 0
        @origin_hash[:block_list] = MultiJson.load(block_list)
      end
    end
    def self.from_local(path)
      lpath = File.expand_path(path)
      raise "Not found file: #{lpath}" unless File.exists?(lpath)
      new(path: lpath, 
          ctime: File.ctime(lpath).to_i, 
          mtime: File.mtime(lpath).to_i,
          block_list: [Digest::MD5.hexdigest(File.read(path))], #lazy load???
          size: File.file?(lpath) ? File.size(lpath) : 0,
          isdir: File.directory?(lpath) ? 1 : 0,
          ifhassubdir: 0, #not use FIXME
          filenum: 0, #not use now
          fs_id: nil, 
          local: true) #标识为本地文件?
    end
    def self.from_remote(rpath)
      Fs.meta(rpath)
    end

    #另一侧的对象
    def mate
      return @_mate if @_mate
      @_mate = local ? self.class.from_remote(relative_path) : self.class.from_local(matepath)
    end
    #获取另一侧的路径，如当前是local，则获取remote的；否则获取local的
    def matepath
      if local
        path.sub(Config.local_app_root, Config.app_root)
      else
        path.sub(Config.app_root, Config.local_app_root)
      end
    end
    def relative_path
      p = path.sub(local ? Config.local_app_root : Config.app_root, '')
      return p[1..-1] if p.start_with?("/")
      p
    end

    def same?
      if isdir?
        #目录直接比较文件内容
        #TODO
      else
        #比较算法， 大小 --> md5
        md5 == mate.md5
      end
    end
    #相应对象比较
    def diff
    end
    def self.diff(rpath)
    end


    def md5
      isdir? ? nil : block_list.first
    end

    def ctime
      Time.at(@origin_hash[:ctime])
    end
    def mtime
      Time.at(@origin_hash[:mtime])
    end
    def isdir?
      isdir.to_i > 0
    end
    def hassub?
      ifhassubdir.to_i > 0
    end

    def info
      origin_hash #TODO FIXME
    end

    def method_missing(method, *args)
      @origin_hash[method.to_sym] #use like: Config.app_name --> :app_name in config file
    end
  end
  
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

    def self.meta(rpath=nil)
      res = get(FILE_BASE_URL, method_params(:meta, path: "#{Config.app_root}/#{rpath}"))
      FileMeta.new(res.body[:list].first)
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
    def self.thumbnail(rpath, opts={})
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
