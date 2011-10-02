HotCocoa::Mappings.map form: NSForm do
  def init_with_options form, options
    form.initWithFrame options.delete(:frame)
  end

  custom_methods do
    def cells= titles
      titles.each do |title|
        addEntry title
      end
    end
  end
end