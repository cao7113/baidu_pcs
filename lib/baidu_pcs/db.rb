require 'baidu_pcs'
module BaiduPcs
  ######################################################
  #              REST structured-data Apis
  #http://developer.baidu.com/wiki/index.php?title=docs/pcs/rest/structured_data_apis_list

  class Db < Base
    DB_BASE_URL = "#{PCS_BASE_URL}/structure"
    TABLE_BASE_URL = "#{DB_BASE_URL}/table"
    DATA_BASE_URL = "#{DB_BASE_URL}/data"

    def self.create_table(tbl_name, opts={})
      params = method_params(:create, v: "1.0", sk: Config.secret_key, table: tbl_name)
      post(TABLE_BASE_URL, params)
    end

    def self.describe_table(tbl_name)
      params = method_params(:describe, v: "1.0", table: tbl_name}
      post(TABLE_BASE_URL, params)
    end

    def self.alter_table(tbl_name, opts={})
      params = method_params(:alter, v: "1.0", table: tbl_name)
      post(TABLE_BASE_URL, params)
    end

    def self.drop_table(tbl_name, opts={})
      params = method_params(:drop, v: "1.0", table: tbl_name)
      post(TABLE_BASE_URL, params)
    end

    def self.restore_table(tbl_name)
      params = method_params(:restore, v: "1.0", table: tbl_name)
      post(TABLE_BASE_URL, params)
    end

    def self.insert_record(tbl_name, records)
      params = method_params(:insert, v: "1.0", table: tbl_name, records: records)
      post(DATA_BASE_URL, params) 
    end

    def self.update_record(tbl_name, records, opts={})
      params = method_params(:update, v: "1.0", table: tbl_name, records: records)
      post(DATA_BASE_URL, params) 
    end

    def self.delete_record(tbl_name, records, opts={})
      params = method_params(:delete, v: "1.0", table: tbl_name, records: records)
      post(DATA_BASE_URL, params) 
    end

    def self.select_record(tbl_name, condition, opts={})
      params = method_params(:select, v: "1.0", table: tbl_name, condition: condition)
      post(DATA_BASE_URL, params) 
    end
  end
end
