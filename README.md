# BaiduPcs

Try [baidu pcs](http://developer.baidu.com/ms/pcs) using ruby!

## Installation

Add this line to your application's Gemfile:

    gem 'baidu_pcs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install baidu_pcs

## Usage

WARNING: in development, just try this, 另一个C语言实现的[命令行工具](https://github.com/emptyhua/baidu_pcs_cli) 

Steps: 

* create a [baidu PCS app](http://developer.baidu.com/ms/pcs) and enable pcs api permissions!
* `baidupcs setup _app_name _api_key _secret_key`
* `baidupcs config` to get an access token
* get help by `baidupcs --help` at any time

List remote files:

```
cao@tj-desktop:~/dev/baidu_pcs$ baidupcs ls
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1291  100  1291    0     0   3721      0 --:--:-- --:--:-- --:--:--  4332
627065058                  books/                     0                          2013-09-10 15:29:08 +0800
3837173268                 img/                       0                          2013-09-10 15:45:35 +0800
2118772017                 personal/                  0                          2013-09-10 15:31:12 +0800
1827382386                 pkg/                       0                          2013-09-10 15:32:36 +0800
3885218819                 dns.jpg                    28253                      2013-09-13 08:41:59 +0800
2730525873                 Gemfile                    127                        2013-09-11 16:29:39 +0800
3974115712                 head.jpg                   17888                      2013-09-11 08:31:41 +0800
2311496999                 MongoDB-manual.pdf         8735748                    2013-09-11 18:55:55 +0800
1319250694                 Note.md                    71                         2013-09-11 18:11:46 +0800
```

## TODO

* Typhoeus优化及客户端模拟
* 分享文件列表，如何自动化完成分享和获取分享链接？
* 对log的支持
* 错误体系构建
* 应用拓广
  * DB备份
  * 静态资源存储支持

## Test and Running

* platform: ubuntu
* ruby: 1.9.3, 2.0.0

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
