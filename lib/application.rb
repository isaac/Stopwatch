require File.join(File.dirname(__FILE__), '..', 'hotcocoa-0.5.1', 'lib', 'hotcocoa')

Dir.glob(File.join(File.dirname(__FILE__), 'vendor', '*.rb')).each do |file|
  require file
end

class Application

  include HotCocoa

  def start
    @app = application :name => "Stopwatch", :delegate => self
    @status = status_item
    load
    @app.run
  end

  def preferences?
    @preferences = [ 'Api Key', 'Account Key', 'Email Address' ]
    @preferences.map { |p| user_defaults["WFM #{p}"] }.compact.size == 3
  end

  def preferences
    size = NSScreen.screens[0].visibleFrame.size
    width, height, margin = 400, 164, 20
    frame = [ size.width - width, size.height - height + 5, width, height ]
    cells = @preferences.map do |field|
      p = NSMutableParagraphStyle.new
      p.setAlignment NSRightTextAlignment
      attributes = { NSForegroundColorAttributeName => NSColor.whiteColor, NSParagraphStyleAttributeName => p }
      field.with_attributes attributes
    end
    @form ||= form :frame => [ margin, margin, width - margin * 2, height - margin * 2], :cells => cells do |f|
      f.setCellSize [ width - margin * 2, 23 ]
      f.setInterlineSpacing 15
    end
    @button ||= button :frame => [ width - 80, 10, 60, 25 ], :title => "Save", :bezel => :recessed do |b|
      b.on_action { save_preferences }
    end
    @panel ||= panel :frame => frame, :title => "Preferences" do |p|
      p.contentView.addSubview @form
      p.contentView.addSubview @button
    end
    @form.cells.each { |cell| cell.setStringValue user_defaults["WFM #{cell.title}"].to_s }
    @panel.orderFrontRegardless
  end

  def save_preferences
    off if @options && @options[:active]
    @form.cells.each do |cell|
      user_defaults["WFM #{cell.title}"] = cell.stringValue
    end
    @panel.close
    @status.view = spinner
    set_staff_id
  end

  def spinner
    @spinner ||= view :frame => [ 0, 0, 29, 25 ] do |v|
      v << progress_indicator(:style => :spinning, :frame => [ 4, 4, 16, 16 ], :start => true, :control_size => NSSmallControlSize)
    end
  end

  def load
    @clients ||= plist(:clients) || []
    @action = nil
    set_status_menu
    return preferences unless preferences?
    if @clients.empty?
      @status.view = spinner
      refresh
    else
      post_timesheets
    end
  end

  def set_status_menu
    @menu = status_menu
    @status.view = nil
    @status.menu = @menu
    @status.image = image :file => "#{lib_path}/../stopwatch.png", :size => [ 17, 17 ]
    @status.alternateImage = image :file => "#{lib_path}/../alternate.png", :size => [ 17, 17 ]
    @status.setHighlightMode true
  end

  def status_menu
    menu :delegate => self do |status|
      @clients.each do |client|
        client_item = menu_item :title => client["Name"]
        client_item.setRepresentedObject client
        job_menu = menu do |jobs|
          client["Jobs"].each do |job|
            job_item = menu_item :title => job["Name"]
            job_item.setRepresentedObject job
            task_menu = menu do |tasks|
              job["Tasks"].each do |task|
                task_item = tasks.item task["Name"]
                task_item.setRepresentedObject task
                task_item.on_action = proc {
                  select({ :task => task_item, :job => job_item, :client => client_item })
                }
              end
            end
            jobs.setSubmenu task_menu, forItem:job_item
            jobs.addItem job_item
          end
        end
        status.setSubmenu job_menu, forItem:client_item
        status.addItem client_item
      end
      status.separator unless @clients.empty?
      status.item "Synchronize", :on_action => proc { reload }
      status.item "Preferences", :on_action => proc { preferences }
      status.separator
      status.item "Quit", :on_action => proc { @app.terminate self }
    end
  end

  def install_shortcut
    shortcut = Shortcut.new
    shortcut.delegate = self
    shortcut.addShortcut
  end

  def hotkeyWasPressed  
    log "You pressed Control+Option+Space"
    @app.tryToPerform nil, with:@status
    item = @menu.itemAtIndex 0
    @menu.performActionForItemAtIndex 0
    log item.target.description
  end

  def notes
    width = @status.title.sizeWithAttributes({ NSFontAttributeName => font(:menu_bar => 0) }).width
    @view = view :auto_resize => [ :width, :height ], :frame => [ 0, 0, width + 20, 40 ]
    @text = text_field :bezel_style => NSTextFieldRoundedBezel, :frame => [ 15, 5, width, 30 ]
    @text.cell.placeholderString = "Notes"
    @view << @text
    @view
  end

  def log(object)
    STDERR << object.description
  end

  def applicationDidFinishLaunching(sender)
    # STDERR << "applicationDidFinishLaunching"
    # install_shortcut
  end

  def applicationWillTerminate(sender)
    save if @options && @options[:active]
  end

  def reload
    off if @options && @options[:active]
    File.delete plist_path :clients if plist? :clients
    @clients = []
    load
  end

  def select(options)
    return on(options) unless options[:task].state == NSOnState
  end

  def on(options)
    if @options
      set_state NSOffState
      off if @options[:active]
    end
    @options = options
    @options[:active] = true
    set_state NSOnState
    start_timer
    set_action
    set_notes
  end

  def off
    @options[:notes] = @text.stringValue
    @options[:active] = false
    update_timer
    save
    @timer.invalidate
    set_title
    set_action
    set_notes
  end

  def set_state(state)
    @options[:task].setState state
    @options[:job].setState state
    @options[:client].setState state
  end

  def set_action(options = @options)
    @action ||= menu_item do |item|
      @menu.insertItem NSMenuItem.separatorItem, atIndex:0
      @menu.insertItem item, atIndex:0
    end
    if options[:active]
      @action.on_action = proc { off }
      @action.title = "Stop"
    else
      @action.on_action = proc { on(options) }
      @action.title = "Start"
    end
  end

  def set_notes
    if @notes
      @menu.removeItemAtIndex(1)
      @notes = nil
    else
      @notes = menu_item  do |item|
        item.view = notes
        @menu.insertItem item, atIndex:1
      end
    end
  end

  def updated
    File.mtime(plist_path(:clients)).strftime("Updated %d/%m/%Y")
  end

  def set_title
    title = [ @options[:task].title.split(' - ').last, @options[:job].title ]
    title << hours(@options) if @options[:active]
    @status.title = " #{title.reverse.join(' - ')}"
  end

  def start_timer
    @options[:start] = Time.now
    @timer = NSTimer.scheduledTimerWithTimeInterval 60,
      target:self, 
      selector:'update_timer', 
      userInfo:nil, 
      repeats:true
    update_timer
  end

  def update_timer
    @options[:end] = Time.now
    set_title
  end

  def save
    xml = "<Timesheet>"
    timesheet(@options).each { |k,v| xml << "<#{k}>#{v}</#{k}>" } 
    xml << "</Timesheet>"
    File.open("#{lib_path}/#{Time.now.to_i}.xml", "w") { |f| f.write xml }
    post_timesheets
  end

  def post_timesheets
    Dir.glob "#{lib_path}/*.xml" do |file|
      MacRubyHTTP.post url(:time), { :payload => File.read(file) } do |response|
        File.delete file if response.status_code == 200 && File.exist?(file)
      end
    end
  end

  def timesheet(options)
    task = options[:task].representedObject
    job = options[:job].representedObject
    {
      "Job" => job["ID"],
      "Task" => task["ID"],
      "Staff" => staff_id,
      "Date" => date(options),
      "Minutes" => minutes(options),
      "Note" => options[:notes]
    }
  end

  def date(options)
    options[:start].strftime "%Y%m%d"
  end

  def hours(options)
    minutes(options).divmod(60).map { |time| time.to_s.size < 2 ? "0#{time}" : time }.join(":")
  end

  def minutes(options)
    (seconds(options) / 60).round
  end

  def seconds(options)
    options[:end] - options[:start]
  end

  def write_plist(name, hash)
    File.open(plist_path(name), "w") { |file| file.write hash.to_plist }
    return hash
  end

  def plist?(name)
    File.exist? plist_path(name)
  end

  def plist(name)
    plist?(name) ? read_plist(File.read(plist_path(name))) : nil
  end

  def plist_path(name)
    File.join lib_path, "#{name}.plist"
  end

  def lib_path
    File.dirname __FILE__
  end

  def clients
    @clients = write_plist(:clients, @jobs.map { |job| job["Client"] }.uniq.map do |client|
      client.merge "Jobs" => @jobs.select { |job| job["Client"]["ID"] == client["ID"] }
    end.sort_by { |client| client["Name"] })
    load
  end

  def refresh
    get url(:jobs, staff_id) do |response|
      @jobs = xml_document(:data => response.body).to_dictionary("Job").map do |job|
        job.merge "Tasks" => [ job["Tasks"]["Task"] ].flatten.compact.sort_by { |task| task["Name"] }
      end.compact.sort_by { |job| job["Name"] }
      clients
    end
  end

  def staff_id
    user_defaults['WFM Staff ID']
  end

  def set_staff_id
    get url(:staff) do |response|
      users = xml_document(:data => response.body).to_dictionary("Staff")
      staff = users.detect { |user| user["Email"] == user_defaults['WFM Email Address'] }
      user_defaults["WFM Staff ID"] = staff["ID"]
      refresh
    end
  end

  def get(uri, &block)
    MacRubyHTTP.get uri do |response|
      if response.status_code == 200
        block.call response
      else
        set_status_menu
        preferences
      end
    end
  end

  def url(name, id = nil)
    "#{host}/#{resource(name,id)}#{params}"
  end

  def host
    "http://api.workflowmax.com"
  end

  def params
    api_keys.map { |k,v| "#{k}=#{v}" }.join("&")
  end

  def resource(name, id)
    resources(id)[name]
  end

  def resources(id)
    {
      :staff => "staff.api/list?",
      :jobs => "job.api/staff/#{id}?detailed=true&",
      :time => "time.api/add?"
    }
  end
  
  def api_keys
    {
      :apiKey => user_defaults['WFM Api Key'],
      :accountKey => user_defaults['WFM Account Key']
    }
  end
  
end

Application.new.start