class Thor::CoreExt::HashWithIndifferentAccess
 protected
  #prefered symbol key vs string key
  def convert_key(key)
    key.is_a?(Symbol) ? key : key.to_sym
  end
end
