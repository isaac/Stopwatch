require 'AIXMLElementSerialize'

HotCocoa::Mappings.map xml_document: NSXMLDocument do
  defaults :options => 0, :error => nil

  def alloc_with_options options
    mask = options.delete :options
    error = options.delete :error
    if options[:string]
      NSXMLDocument.alloc.initWithXMLString options.delete(:string), options:mask, error:error
    elsif options[:url]
      url = NSURL.alloc.initWithString options.delete(:url)
      NSXMLDocument.alloc.initWithContentsOfURL url, options:mask, error:error
    elsif options[:file] || options[:data]
      data = options.delete(:data) || NSData.alloc.initWithContentsOfFile(options.delete(:file))
      NSXMLDocument.alloc.initWithData data, options:mask, error:error
    else
      raise "Must provide either :string, :url, :file or :data when constructing an NSXMLDocument"
    end
  end

  custom_methods do
    def xpath query
      nodesForXPath query, error:nil
    end
    
    def to_dictionary query
      xpath("//#{query}").map { |node| node.toDictionary[query] }
    end
  end
end
