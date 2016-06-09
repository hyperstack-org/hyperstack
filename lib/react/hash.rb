class Hash

  alias_method :_pre_react_patch_initialize, :initialize

  def initialize(defaults = undefined, &block)
    if (`defaults===null`)
      _pre_react_patch_initialize(&block)
    else
      _pre_react_patch_initialize(defaults, &block)
    end
  end

end
