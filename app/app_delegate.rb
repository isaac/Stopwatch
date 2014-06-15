class AppDelegate
  def applicationDidFinishLaunching(notification)
  end

  def write_plist(name, hash)
    File.open(plist_path(name), "w") { |file| file.write hash.to_plist }
    return hash
  end

  def plist?(name)
    File.exist? plist_path(name)
  end

  def plist(name)
    plist?(name) ? load_plist(File.read(plist_path(name))) : nil
  end

  def plist_path(name)
    File.join lib_path, "#{name}.plist"
  end

  def lib_path
    File.dirname __FILE__
  end

  def clients
    @clients = write_plist(:clients, @jobs.map { |job| job["Client"] }.uniq.compact.map do |client|
      client[:size] = client["Name"].sizeWithAttributes({ NSFontAttributeName => NSFont.menuFontOfSize(0) }).width
      client.merge :jobs => @jobs.select { |job| job["Client"]["ID"] == client["ID"] }
    end.sort_by { |client| client["Name"] })
    load
  end

  def refresh
    get url(:jobs) do |xml|
      @jobs = xml.to_dictionary("Job").map do |job|
        job.merge :tasks => [ job["Tasks"]["Task"] ].flatten.compact.sort_by { |task| task["Name"] }
      end.compact.sort_by { |job| job["Name"] }
      clients
    end
  end

  def staff_id
    665
  end

  def get(uri, &block)
    BW::HTTP.get uri do |response|
      if response.status_code == 200
        block.call xml_document(response.body.to_s)
      else
        block.call response
      end
    end
  end

  def url(name, id = nil)
    "#{ host }/#{ resources[name] }#{ params }"
  end

  def host
    "http://api.workflowmax.com"
  end

  def params
    api_keys.map { |k,v| "#{k}=#{v}" }.join("&")
  end

  def resources
    {
      :jobs => "job.api/staff/#{ staff_id }?detailed=true&",
      :time => "time.api/add?"
    }
  end
  
  def api_keys
    {
      :apiKey => "97F603CFC65C4BE282A65B8DC809981F",
      :accountKey => "3F6CAA3A1B3A4170A134D0EF8E0B1AA7"
    }
  end

  def user_defaults
    App::Persistence
  end

  def xml_document(string)
    ::NSXMLDocument.alloc.initWithXMLString string, options:0, error:nil
  end
end

class NSXMLDocument
  def xpath query
    nodesForXPath query, error:nil
  end
  
  def to_dictionary query
    xpath("//#{query}").map { |node| node.toDictionary[query] }
  end
end
