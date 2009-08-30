HotCocoa::Mappings.map :panel => :NSPanel do
    
  defaults  :style => [ :hud, :non_activating, :titled, :utility, :closable ],
            :backing => :buffered, 
            :defer => true
            
  constant :backing, :buffered => NSBackingStoreBuffered
  
  constant :style,   {
    :hud                => NSHUDWindowMask,
    :utility            => NSUtilityWindowMask,
    :non_activating     => NSNonactivatingPanelMask,
    :modal              => NSDocModalWindowMask,
    :borderless         => NSBorderlessWindowMask, 
    :titled             => NSTitledWindowMask, 
    :closable           => NSClosableWindowMask, 
    :miniaturizable     => NSMiniaturizableWindowMask, 
    :resizable          => NSResizableWindowMask,
    :textured           => NSTexturedBackgroundWindowMask
  }

  def init_with_options(panel, options)
    panel.initWithContentRect options.delete(:frame), 
                               styleMask:options.delete(:style), 
                               backing:options.delete(:backing), 
                               defer:options.delete(:defer)
  end
end