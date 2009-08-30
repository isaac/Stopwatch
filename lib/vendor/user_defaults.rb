HotCocoa::Mappings.map :user_defaults => :NSUserDefaults do

  def alloc_with_options(options)
    NSUserDefaults.standardUserDefaults
  end

  custom_methods do
    def []=(key, value)
      if value.nil?
        delete(key)
      else
        setObject(value, forKey:key)
      end
      synchronize
    end

    def [](key)
      objectForKey(key)
    end

    def delete(key)
      removeObjectForKey(key)
      synchronize
    end

    def defaults=(hash)
      registerDefaults hash
    end

    def defaults
      dictionaryRepresentation
    end

  end
end
