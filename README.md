# BaiduPcs

Try baidu pcs using ruby!

## Installation

Add this line to your application's Gemfile:

    gem 'baidu_pcs'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install baidu_pcs

## Usage

Steps: 

* create a baidu app in baidu dev center and enable pcs api permissions!
* `baidu_pcs setup _app_name _api_key _secret_key`
* `baidu_pcs config`
* get help by `baidupcs --help`
* another bins: `baidupcs_db, baidupcs_local`

## TODO

* 文件夹批量索引和同步问题
* 分享文件列表
* 应用拓广

## Test and Running

* platform: ubuntu
* ruby: 1.9.3, 2.0.0

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
