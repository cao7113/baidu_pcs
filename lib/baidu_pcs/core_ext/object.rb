class Object
  def blank?
    nil? || (respond_to?(:empty?) && empty?)
  end
end
