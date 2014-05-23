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
    attr_accessor :origin_hash, :_mate, :_rpath
    def initialize(hash)
      raise "Invalid hash for file meta" if hash.blank?
      @_rpath = hash[:path]
      @origin_hash = hash
      #temp fix json parse FIXME
      if block_list.is_a?(String) and block_list.length > 0
        @origin_hash[:block_list] = MultiJson.load(block_list)
      end
    end
    def self.from_local(path)
      lpath = File.expand_path(path)
      #raise "Not found file: #{lpath}" unless File.exists?(lpath)
      return nil unless File.exists?(lpath)
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
    rescue =>e
      $stderr.puts e.message
      nil
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
    def self.local_path(rpath)
      "#{Config.local_app_root}/#{rpath}"
    end
    def self.remote_path(rpath)
      "#{Config.app_root}/#{rpath}"
    end
    def local_path
      local ? path : matepath
    end
    def remote_path
      local ? matepath : path
    end

    #相应对象比较
    def diff
      unless mate
        puts "Its mate(#{matepath}) does not exist now! you can #{local ? 'upload' : 'download'} it!"
        return
      end
      result = ""
      #比对大小， md5
      if size == mate.size
        result = "大小相等"
        if md5 == mate.md5
          result = "MD5相等"
        end
      else
        result = "大小不等"
      end
      puts result
    end
    def self.diff(rpath)
      meta = from_remote(rpath) rescue nil
      unless meta
        $stderr.puts "Remote asset: #{rpath} does not exist!"
        local_path = FileMeta.local_path(rpath)
        if File.exists?(local_path)
          $stderr.puts "Local path: #{local_path} exists! upload?"
        else
          $stderr.puts "Local path: #{local_path} does not exists, maybe typo error!"
        end
        return
      end
      if meta.isdir? 
        $stderr.puts "Warning：目前仅支持文件比较，这是远程目录：#{meta.remote_path}"
        return
      end
      meta.diff
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
      "#{isdir? ? 'Dir' : 'File'}(#{fs_id}): #{path} ctime: #{ctime} mtime: #{mtime} size: #{size} blocks: #{block_list} #{'Has subdir' if hassub?}"
    end

    def method_missing(method, *args)
      @origin_hash[method.to_sym]
    end
  end
  
  class Fs < Base
    FILE_BASE_URL = "#{PCS_BASE_URL}/file"
   
    ERRORS = YAML.load(BaiduPcs.gempath('template/file_data_apis_error.yml'))

    def detail_error
      if has_error?
        error_code = error.hash[:error_code]
        ERRORS[error_code]
      end
    end

    #path:  local file path
    #rpath: 上传文件路径（含上传的文件名称)
    def self.upload(path, rpath=nil, opts={})
      params = method_params(:upload, path: "#{Config.app_root}/#{rpath||File.basename(path)}")
      mkdir(File.dirname(rpath)) unless opts.delete(:not_check_dir) #检查远端路径是否存在，不存在则创建
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
      "#{FILE_BASE_URL}?#{params.to_query_str}"
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
      params = method_params(:generate, path: "#{Config.app_root}/#{rpath}").merge(opts.extract!(:quality, :height, :width))
      #get("#{PCS_BASE_URL}/thumbnail", params, opts)
      #TODO stub 测试，近构建链接
      "#{PCS_BASE_URL}/thumbnail?" + params.to_query_str
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
