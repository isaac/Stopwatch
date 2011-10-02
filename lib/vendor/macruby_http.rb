# -*- coding: utf-8 -*-

# The MIT License
# 
# Copyright (c)2010 Matt Aimonetti
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

class MacRubyHelper
  
  module DownloadHelper
  
    # Download helper makes file download trivial.
    # 
    # The result of the download can be processed by a block or a delegator.
    # A block will always take precedence over a delegator, meaning that you can't
    # pass a delegator and use a block, you have to choose which approach
    # you want to use.
    # NOTE: in the case of a non blocking download, the delegation block can be called multiple times
    # due to a bug in Cocoa. (or maybe it's an undocumented feature ;)).
    #
    # ==== Parameters
    # url<String>:: url of the resource to download
    # options<Hash>:: options used for the query, see +MacRubyHTTP::Query.initialize+ for more details
    # &block<block>:: block which is called when the file is downloaded
    #
    # ==== Options
    # :method<String, Symbol>:: An optional value which represents the HTTP method to use
    # :payload<String>::    - data to pass to a POST, PUT, DELETE query.
    # :delegation<Object>:: - class or instance to call when the file is downloaded.
    #                         the handle_query_response method will be called on the
    #                         passed object
    # :save_to<String>::    - path to save the response to
    # :credential<Hash>::   - should contains the :user key and :password key
    #                         By default the credential will be saved for the entire session
    #
    # TODO
    # :progress <Proc>::    Proc to call everytime the downloader makes some progress
    # :cache_storage
    #
    # ==== Examples
    #   download("http://www.macruby.org/files/MacRuby%200.4.zip", {:save_to => '~/tmp/macruby.zip'.stringByStandardizingPath}) do |macruby|
    #     NSLog("file downloaded!")
    #   end
    #
    #   download "http://macruby.org" do |mr|
    #     # The response object has 3 accessors: status_code, headers and body
    #     NSLog("status: #{mr.status_code}, Headers: #{mr.headers.inspect}")
    #   end
    # 
    #   path = File.expand_path('~/macruby_tmp.html')
    #   window :frame => [100, 100, 500, 500], :title => "HotCocoa" do |win|
    #     download "http://macruby.org", {:save_to => path} do |homepage|
    #       win << label(:text => "status code: #{homepage.status_code}", :layout => {:start => false})
    #       win << label(:text => "Headers: #{homepage.headers.inspect}", :layout => {:start => false})
    #     end
    #   end
    #
    #   download "http://macruby.org/users/matt", :delegation => @downloaded_file, :method => 'PUT', :payload => {:name => 'matt aimonetti'}
    #   
    #   download "http://macruby.org/roadmap.xml", :delegation => self
    #
    #   download "http://localhost:5984/couchrest-test/", :method => 'POST', :payload => '{"user":"mattaimonetti@gmail.com","zip":92129}', :delegation => self
    #
    #   download("http://yoursite.com/login", {:credential => {:user => 'me', :password => 's3krit'}}) do |test|
    #     NSLog("response received: #{test.headers} #{test.status_code}")
    #   end
    # 
    #   # We can also do the same thing but synchronously and block the runloop  
    #   download "http://macruby.org", :immediate => true, :save_to => '~/tmp/site.html'.stringByStandardizingPath do |mr|
    #     p "file downloaded, let's continue"
    #   end
    #    
    def download(url, opts={}, &block)
      http_method = opts.delete(:method) || 'GET'
      delegator   = block_given? ? block : opts.delete(:delegation)
      MacRubyHTTP::Query.new( url, http_method, opts.merge({:delegator => delegator}))
    end
    
  end
end

module MacRubyHTTP
  VERSION    = '0.3.2' unless self.const_defined?("VERSION")
  
  class Response
    attr_reader :body
    attr_reader :headers
    attr_accessor :status_code
    attr_reader :url
    
    def initialize(values={})
      values.each do |k,v|
        self.instance_variable_set("@#{k.to_sym}", v)
      end
    end
  end
  
  # Make a GET request
  #
  # ==== Examples
  #
  # MacRubyHTTP.get("http://merb.lighthouseapp.com/projects.json", {:credential => {:user => 'matt', :password => 'aimonetti'}}) do |lh|
  # NSLog(lh.inspect)
  # end
  #
  def self.get(url, options={}, &block)
    delegator = block_given? ? block : options.delete(:delegation)
    MacRubyHTTP::Query.new( url, 'GET', options.merge({:delegator => delegator}) )
  end
  
  # Make a POST request
  def self.post(url, options={}, &block)
    delegator = block_given? ? block : options.delete(:delegation)
    MacRubyHTTP::Query.new( url, 'POST', options.merge({:delegator => delegator}) )
  end
  
  # Make a PUT request
  def self.put(url, options={}, &block)
    delegator = block_given? ? block : options.delete(:delegation)
    MacRubyHTTP::Query.new( url, 'PUT', options.merge({:delegator => delegator}) )
  end
  
  # Make a DELETE request
  def self.delete(url, options={}, &block)
    delegator = block_given? ? block : options.delete(:delegation)
    MacRubyHTTP::Query.new( url, 'DELETE', options.merge({:delegator => delegator}) )
  end

  # API usage:
  #
  # MacRubyHTTP::Query.new('http://google.com', :get, self)
  class Query
    attr_accessor :request
    attr_accessor :connection
    attr_accessor :credential # username & password has a hash
    attr_accessor :proxy_credential # credential supplied to proxy servers
    attr_accessor :post_data
    attr_reader   :method

    attr_reader :response
    attr_reader :status_code
    attr_reader :response_headers
    attr_reader :response_size
    attr_reader :options
    attr_reader :path_to_save_response


    # ==== Parameters
    # url<String>:: url of the resource to download
    # http_method<String, Symbol>:: An optional value which represents the HTTP method to use
    # options<Hash>:: optional options used for the query
    #
    # ==== Options
    # :payload<String>   - data to pass to a POST, PUT, DELETE query.
    # :delegator         - Proc, class or object to call when the file is downloaded.
    # a proc will receive a Response object while the passed object
    # will receive the handle_query_response method
    # :save_to<String>   - Path to save the response body
    # :headers<Hash>     - headers send with the request
    # :blocking<Boolean> - should the main runloop be blocked or not (default: false)
    # Anything else will be available via the options attribute reader.
    #
    def initialize(url, http_method = 'GET', options={})
      @method = http_method.upcase.to_s
      @delegator = options.delete(:delegator) || self
      @path_to_save_response = options.delete(:save_to)
      @payload = options.delete(:payload)
      @credential = options.delete(:credential) || {}
      @credential = {:user => '', :password => ''}.merge(@credential)
      @headers = options.delete(:headers) || {}
      @blocking = options.delete(:blocking) || false
      immediate = options.delete(:immediate)
      @options = options

      if immediate
        immediate_download(url)
      else
        initiate_request(url)
        connection.start
        connection
      end
    end
    
    def to_save?
      !@path_to_save_response.nil?
    end
     
    # if we don't want to go through the callbacks
    # we can pass the :immediate => true option
    # and the operation will block the run loop
    def immediate_download(url_string)
      url = NSURL.URLWithString(url_string)
      data = NSMutableData.dataWithContentsOfURL(url)

      @response = ::MacRubyHTTP::Response.new(:status_code => 200, :body => data, :headers => response_headers, :url => url_string)
      if to_save?
        if data
          @response.status_code = 200
          data.writeToFile(@path_to_save_response, atomically:true)
        else
          @response.status_code = 404
          puts "Failed to download #{url_string}"
        end
      end       
      if @delegator.is_a?(Proc)
        @delegator.call( @response )
      elsif !@delegator.nil? && @delegator.respond_to?(:handle_query_response)
        @delegator.send(:handle_query_response, @response)
      else
        handle_query_response(@response)
      end
    end

    protected

    def initiate_request(url_string)
      # http://developer.apple.com/documentation/Cocoa/Reference/Foundation/Classes/nsrunloop_Class/Reference/Reference.html#//apple_ref/doc/constant_group/Run_Loop_Modes
      # NSConnectionReplyMode
      @url = NSURL.URLWithString(url_string)
      @request = NSMutableURLRequest.requestWithURL(@url,
                                          cachePolicy:NSURLRequestReloadIgnoringCacheData,
                                          timeoutInterval:30.0)
      @request.setHTTPMethod @method
      @request.allHTTPHeaderFields = @headers unless @headers.empty?

      # @payload needs to be converted to data
      unless method == 'GET' || @payload.nil?
        @payload = @payload.to_s.dataUsingEncoding(NSUTF8StringEncoding)
        @request.setHTTPBody @payload
      end
      @connection = NSURLConnection.connectionWithRequest(request, delegate:self)
      @request.instance_variable_set("@done_loading", false)
      def @request.done_loading; @done_loading; end
      def @request.done_loading!; @done_loading = true; end
      
      if @blocking
        NSRunLoop.currentRunLoop.runUntilDate(NSDate.alloc.init) until @request.done_loading
      end
    end

    def connection(connection, didReceiveResponse:response)
      @status_code = response.statusCode
      @response_headers = response.allHeaderFields
      @response_size = response.expectedContentLength.to_f
    end
    
    # This delegate method get called every time a chunk of data is being received
    def connection(connection, didReceiveData:received_data)
      @received_data ||= NSMutableData.new
      @received_data.appendData(received_data)
    end
    
    def connection(connection, willSendRequest:request, redirectResponse:redirect_response)
      # puts "redirected #{request.description}"
      new_request = request.mutableCopy
      new_request.allHTTPHeaderFields = @headers unless @headers.empty?
      @connection = NSURLConnection.connectionWithRequest(new_request, delegate:self)
      new_request
    end

    # The transfer is done and everything went well
    def connectionDidFinishLoading(connection)
      @request.done_loading!

      response_body = @received_data.dup if @received_data
      response_body.writeToFile(@path_to_save_response, atomically:true) if @received_data && to_save? && status_code == 200
      @response = ::MacRubyHTTP::Response.new(:status_code => status_code, :body => response_body, :headers => response_headers, :url => @url)
      # Don't reset the received data since this method can be called multiple times if the headers report the wrong length.
      # @received_data = nil
      if @delegator.is_a?(Proc)
        @delegator.call( @response, self )
      elsif !@delegator.nil? && @delegator.respond_to?(:handle_query_response)
        @delegator.send(:handle_query_response, @response)
      else
        handle_query_response(@response)
      end
    end
    
    # backup method when the download went well
    def handle_query_response(response)
      NSLog("you need to set your own delegation, your delegate object doesn't response to 'handle_query_response'")
    end

    def connection(connection, didReceiveAuthenticationChallenge:challenge)
      NSLog("auth required")
      if (challenge.previousFailureCount == 0)
        # by default we are keeping the credential for the entire session
        # Eventually, it would be good to let the user pick one of the 3 possible credential persistence options:
        # NSURLCredentialPersistenceNone,
        # NSURLCredentialPersistenceForSession,
        # NSURLCredentialPersistencePermanent
        new_credential = NSURLCredential.credentialWithUser(credential[:user], password:credential[:password], persistence:NSURLCredentialPersistenceForSession)
        challenge.sender.useCredential(new_credential, forAuthenticationChallenge:challenge)
      else
          challenge.sender.cancelAuthenticationChallenge(challenge)
          NSLog('Auth Failed :(')
      end
    end
    
  end
end