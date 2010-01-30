module Kernel
  
  alias_method :default_framework, :framework
  
  def framework(name)
    if default_framework(name)
      HotCocoa::Mappings.framework_loaded
      true
    else
      false
    end
  end
  
end