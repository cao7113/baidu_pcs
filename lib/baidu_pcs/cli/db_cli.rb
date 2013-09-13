require 'baidu_pcs/cli/base_cli'
require 'baidu_pcs/db'

module BaiduPcs::Cli
  class DbCli < BaseCli

    desc 'create_table TBL_NAME', ' create a table'
    def create_table(tbl_name)
      say BaiduPcs::Db.create_tbl(tbl_name)
    end

    desc 'desc_table TBL_NAME', ' create a table'
    def desc_table(tbl_name)
      say BaiduPcs::Db.describe_table(tbl_name)
    end
  end
end
