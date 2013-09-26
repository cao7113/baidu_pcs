class Hash
  #TODO 先检查是否已定义
  def to_query_str
    map{|k, v| "#{k}=#{v}"}.join("&") #可能有些转义问题
  end
end
