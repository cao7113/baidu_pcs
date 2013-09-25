require 'baidu_pcs/cli/base_cli'
require 'baidu_pcs/fs'

module BaiduPcs::Cli
  class FsCli < BaseCli
    default_task :list

    no_tasks do
      def print_item(item)
        print_in_columns [item[:fs_id], "#{item[:path].sub(BaiduPcs::Config.app_root+'/', '')}#{'/' if item[:isdir]==1}", item[:size], "#{Time.at(item[:mtime])}"] 
      end
    end
    
    desc 'upload LOCAL_PATH [, RPATH]', 'upload a local file /path/to/file --> /apps/appname/[rpath|file]'
    option :ondup, type: :string, desc: <<-Desc, default: :newcopy
overwrite：表示覆盖同名文件；newcopy：表示生成文件副本并进行重命名，命名规则为“文件名_日期.后缀”。
    Desc
    def upload(local_path, rpath=nil)
      res = BaiduPcs::Fs.upload(File.expand_path(local_path), rpath, options.dup)
      print_item res.body
    end

    desc "batch_upload LOCAL_DIR RDIR [, FILE_PATTERN]", <<-Desc
    upload multiple local files into remote dir for sync or backup"
    注意模式需要转义，如：
    cao@tj-desktop:~/dev/baidu_pcs$ be bin/baidupcs batch_upload test test \*.txt --noprogress -r --dryrun
    t2/t22/t3/a2.txt
    t2/t22/t3/a1.txt
    Desc
    option :dryrun, desc: "列出要操作的文件", type: :boolean #, default: true 
    option :ondup, type: :string, desc: <<-Desc, default: :newcopy
overwrite：表示覆盖同名文件；newcopy：表示生成文件副本并进行重命名，命名规则为“文件名_日期.后缀”。
    Desc
    option :recursive, desc: "对子目录递归上传", type: :boolean, aliases: [:r]
    def batch_upload(local_dir, rdir, file_pattern="*")
      opts = options.dup
      local_path = File.expand_path(local_dir)
      origin_local_path = local_path
      if opts.delete(:recursive)
        local_path += "/**"
      end
      select_files = Dir.glob(File.join(local_path, file_pattern)).select{|f| File.file?(f)}
      if opts.delete(:dryrun)
        select_files.each{|f| puts f.sub("#{origin_local_path}/", "")}
        return
      end
      cnt = 0
      select_files.each do |f|
        BaiduPcs::Fs.upload(f, "#{rdir}#{rdir ? '/' : ''}#{f.sub("#{origin_local_path}/", "")}", opts.dup) #dup good
        cnt += 1
        puts "==uploading #{f} ..." 
      end
      puts "upload files: #{cnt} files"
    end

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

    desc 'streamurl RPATH', 'get a stream-file url for using online, e.g. <img src="_streamurl" />'
    def streamurl(rpath)
      say BaiduPcs::Fs.streamurl(rpath)
    end
    map url: :streamurl

    desc 'mkdir RPATH', 'mkdir remote path, e.g. mkdir path/to/newdir, support b/c1/d2'
    def mkdir(rpath)
      say BaiduPcs::Fs.mkdir(rpath).body
    end

    desc 'meta RPATH', 'get meta info about a remote path, file or directory'
    def meta(rpath)
      say BaiduPcs::Fs.meta(rpath).body
    end

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
    map del: :delete

    desc 'search KEYWORD [, RPATH]', 'search a keyword in remote path'
    option :recursive, type: :boolean, aliases: :r, default: false
    def search(keyword, rpath=nil)
      say BaiduPcs::Fs.search(keyword, rpath, options).body
    end
  end
end
