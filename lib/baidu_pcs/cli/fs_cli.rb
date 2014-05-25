require 'baidu_pcs/cli/base_cli'
require 'baidu_pcs/fs'

module BaiduPcs::Cli
  class FsCli < BaseCli
    #default_task :list

    no_tasks do
      def print_item(item)
        print_in_columns [item[:fs_id], "#{item[:path].sub(BaiduPcs::Config.app_root+'/', '')}#{'/' if item[:isdir]==1}", item[:size], "#{Time.at(item[:mtime])}"] 
      end
    end

    desc "upload LOCAL_PATH REMOTE_PATH [, FILE_PATTERN='*']", <<-Desc
upload/put (multiple) local files into remote path
注意模式需要转义，如：
baidupcs batch_upload test test \*.txt --noprogress -r --dryrun
t2/t22/t3/a2.txt
t2/t22/t3/a1.txt
Desc
    option :dryrun, desc: "列出要操作的文件", type: :boolean, aliases: [:d] #, default: true 
    option :ondup, type: :string, desc: <<-Desc, default: :newcopy
overwrite：表示覆盖同名文件；newcopy：表示生成文件副本并进行重命名，命名规则为“文件名_日期.后缀”。
    Desc
    option :recursive, desc: "对子目录递归上传", type: :boolean, aliases: [:r], default: true
    def upload(local_dir, rdir, file_pattern="*")
      logger_path = File.join(Dir.pwd, "pcs_upload_#{File.basename(local_dir)}.log")
      logger = File.open(logger_path, "w+")
      logger.sync = true
      logger.puts "==I: #{Time.now.to_s} uploading from #{local_dir} to #{rdir} for #{file_pattern}..."
      logger.puts "==I: ...more log info in #{logger_path} ..."
      opts = options.dup
      local_path = File.expand_path(local_dir)
      if File.file?(local_path)
        logger.puts "====upload a file: #{local_path} ..."
        rpath = rdir.end_with?('/') ? "#{rdir}#{File.basename(local_dir)}" : rdir
        res = BaiduPcs::Fs.upload(local_path, rpath, opts.slice(:ondup))
        print_item res.body
        return
      end
      logger.puts "====recursive upload a loal dir: #{local_path}"
      origin_local_path = local_path
      if local_dir.end_with?('/') and File.basename(local_dir) != File.basename(rdir)
        rdir += File.basename(local_dir) 
      end
      if opts.delete(:recursive)
        local_path += "/**"
      end
      select_files = Dir.glob(File.join(local_path, file_pattern)).sort
      if opts.delete(:dryrun)
        select_files.each{|f| puts f.sub("#{origin_local_path}/", "")}
        return
      end
      cnt = 0
      total = select_files.size
      select_files.each do |f|
        cnt += 1
        begin
          r_path = "#{rdir}#{'/' unless rdir.end_with?('/')}#{f.sub("#{origin_local_path}/", "")}"
          logger.puts "==uploading (#{cnt}/#{total}) #{f} --> #{r_path} ..." #if options[:verbose]
          BaiduPcs::Fs.upload(f, r_path, opts.dup) #dup good
        rescue =>e
          logger.puts "==Error: upload #{f} to #{r_path}, message: #{e.message}..."
        end
      end
      logger.puts "==upload files: #{cnt} files"
    end
    map put: :upload

    desc 'download RPATH', 'download a remote file, DONOT!!! support download a dir'
    option :tosync, desc: "是否下载到本地同步目录！", type: :boolean, default: false
    def download(rpath)
      opts = options.dup
      local_app_root = opts.delete(:tosync) ? BaiduPcs::Config.local_app_root : Dir.pwd
      local_path = "#{local_app_root}/#{rpath}"
      body = BaiduPcs::Fs.download(rpath, opts).body
      FileUtils.mkdir_p(File.dirname(local_path))
      if File.exists?(local_path)
        extname = File.extname(local_path)
        timestamp_ext = ".#{Time.now.strftime('%Y%m%d%H%M%S')}-#{rand(100)}#{extname}"  
        if extname.blank?
          local_path += timestamp_ext  
        else
          local_path.gsub!(extname, timestamp_ext)
        end
      end
      File.binwrite(local_path, body)
      say local_path
    end
    map get: :download

    desc 'streamurl RPATH', 'get a stream-file url for using online, e.g. <img src="_streamurl" />'
    def streamurl(rpath)
      say BaiduPcs::Fs.streamurl(rpath)
    end
    map url: :streamurl

    desc "thumbnail RPATH", "获取缩略图"
    option :quality, type: :numeric, desc: "缩略图的质量，默认为“100”，取值范围(0,100]", default: 100
    option :height, type: :numeric, desc: "指定缩略图的高度，取值范围为(0,1600]", default: 200
    option :width, type: :numeric, desc: "指定缩略图的宽度，取值范围为(0,1600]", default: 200
    def thumbnail(rpath)
      opts = options.dup
      say BaiduPcs::Fs.thumbnail(rpath, opts)
    end

    desc 'mkdir RPATH', 'mkdir remote path, e.g. mkdir path/to/newdir, support b/c1/d2'
    def mkdir(rpath)
      say BaiduPcs::Fs.mkdir(rpath).body
    end

    desc 'meta [RPATH]', 'get meta info about a remote path, file or directory'
    def meta(rpath=nil)
      fmeta = BaiduPcs::Fs.meta(rpath)
      puts fmeta.info
    end

    #因为批量上传中ondup参数没有重复忽略的选项，所以用这个方法进行解决
    desc "compare_dir [RDIR]", "根据文件名差异对目录进行同步"
    option :ondup, type: :string, desc: <<-Desc, default: :newcopy
overwrite：表示覆盖同名文件；newcopy：表示生成文件副本并进行重命名，命名规则为“文件名_日期.后缀”。
    Desc
    option :upload, type: :boolean, desc: "Upload when need"
    def compare_dir(rpath=nil)
      opts = options.dup
      res = BaiduPcs::Fs.list(rpath, {})
      files = res.body[:list].map do |item|
        item[:path].to_s.sub("#{BaiduPcs::Config.app_root}/", '')
      end.sort
      lfiles = Dir[File.join(*[BaiduPcs::Config.local_app_root, rpath, "*"].compact)].map{|f| f.sub("#{BaiduPcs::Config.local_app_root}/", '')}.sort
      to_down = files - lfiles
      if to_down.size > 0
        say "Local missing #{to_down.size} files:"
        #download ???
        say to_down.join(" ")
      end
      to_up = lfiles - files
      if to_up.size > 0
        say "Local has #{to_up.size} more files: "
        need_upload = opts.delete(:upload)
        to_up.each do |f|
          puts "==upload file: #{f} ..."
          BaiduPcs::Fs.upload("#{BaiduPcs::Config.local_app_root}/#{f}", f, opts.dup) if need_upload
        end
        say to_up.join(" ")
      end
      say "Synced #{to_down.size} missing and #{to_up.size} more at local #{BaiduPcs::Config.local_app_root}/#{rpath} ..."
    end
    map cmpd: :compare_dir

    desc 'compare_file RPATH', 'check version is synced for a file or a directory'
    def compare_file(rpath)
      BaiduPcs::FileMeta.diff(rpath)
    end
    map cmpf: :compare_file

    desc 'list [RPATH]', 'list a remote path for all file or directory'
    option :by, desc: "sort field, possible values: [time | name | size]",  type: :string 
    option :order, desc: "possible value: [asc | desc]", type: :string#, default: :desc
    option :limit, desc: "n1-n2, default n1=0", type: :string 
    option :onlyname, desc: "just list name", type: :boolean #, default: true
    def list(rpath=nil)
      opts = options.dup
      onlyname = opts.delete(:onlyname)
      res = BaiduPcs::Fs.list(rpath, opts)
      res.body[:list].each do |item|
        if onlyname
          puts "#{File.basename(item[:path])}#{'/' if item[:isdir]==1}"
        else
          print_item(item)
        end
      end
    end
    map ls: :list

    #TODO compare dir
    #目录文件比较算法

    desc 'move FROM_RPATH, TO_RPATH', 'move a remote path/to/from --> path/to/to'
    def move(from_rpath, to_rpath)
      say BaiduPcs::Fs.move(from_rpath, to_rpath).body
    end
    map mv: :move

    desc 'copy FROM_RPATH, TO_RPATH', 'copy a remote path/to/from --> path/to/to'
    def copy(from_rpath, to_rpath)
      say BaiduPcs::Fs.copy(from_rpath, to_rpath).body
    end
    map cp: :copy

    desc 'delete RPATH', 'delete a remote path'
    option :force, type: :boolean, aliases: :f, default: false
    def delete(rpath)
      if options[:force] || yes?("Are you sure to delte #{rpath}?")
        say BaiduPcs::Fs.delete(rpath).body
      else
        say "Cancel to delete #{rpath}"
      end
    end
    map rm: :delete

    desc 'search KEYWORD [, RPATH]', 'search a keyword in remote path'
    option :recursive, type: :boolean, aliases: :r, default: false
    def search(keyword, rpath=nil)
      say BaiduPcs::Fs.search(keyword, rpath, options).body
    end
  end
end
