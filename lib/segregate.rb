require 'uri'
require 'hashie'
require 'segregate/http_methods'
require 'segregate/http_regular_expressions'

class Segregate
  attr_reader :uri
  attr_accessor :request_method, :status_code, :status_phrase, :http_version, :headers, :body

  def method_missing meth, *args, &block
    if @uri.respond_to? meth
      @uri.send meth, *args, &block
    else
      super
    end
  end

  def respond_to?(meth, include_private = false)
    @uri.respond_to?(meth, include_private) || super
  end

  def initialize callback = nil 
    @callback = callback
    @http_version = [nil, nil]

    @headers = Hashie::Mash.new
    @body = ""

    @request = false
    @response = false

    @first_line_complete = false
    @headers_complete = false
    @body_complete = false
    @header_orders = []
  end

  def request?
    @request
  end

  def response?
    @response
  end

  def headers_complete?
    @headers_complete
  end

  def body_complete?
    @body_complete
  end

  def request_line
    request? ? "%s %s HTTP/%d.%d" % [request_method, request_url.to_s, *http_version] : nil
  end

  def status_line
    response? ? "HTTP/%d.%d %d %s" % [*http_version, status_code, status_phrase] : nil
  end

  def request_url
    uri ? uri.to_s : nil
  end

  def major_http_version
    http_version[0]
  end

  def major_http_version= val
    http_version[0] = val
  end

  def minor_http_version
    http_version[1]
  end

  def minor_http_version= val
    http_version[1] = val
  end

  def update_content_length
    if @body_complete
      @headers['content-length'] = @body.length.to_s
      @header_orders.push 'content-length' unless @header_orders.include? 'content-length'
      @headers.delete 'content-encoding'
      @header_orders.delete 'content-encoding'
    end
  end

  def raw_data
    raw_message = ""
    update_content_length

    request? ? raw_message << request_line + "\r\n" : raw_message << status_line + "\r\n"

    @header_orders.each do |header|
      raw_message << "%s: %s\r\n" % [header, headers[header]]
    end
    raw_message << "\r\n"

    raw_message << @body + "\r\n\r\n" unless @body.empty?
  end

  def parse data
    data = StringIO.new data

    read_first_line data unless @first_line_complete
    read_headers data unless @headers_complete
    read_body data unless data.eof?

    @callback.on_message_complete self if @callback.respond_to?(:on_message_complete) && @headers_complete && (no_body? || @body_complete)
  end

  private

  def no_body?
    (@headers['content-length'].nil? && @headers['content-encoding'].nil?)
  end

  def read data, size = nil
    if size
      data.read(size + 2).chomp("\r\n")
    else
      data.readline.chomp("\r\n")
    end
  end

  def read_first_line data
    @callback.on_message_begin self if @callback.respond_to?(:on_message_begin)
    line = read data

    if line =~ REQUEST_LINE
      parse_request_line line
    elsif line =~ STATUS_LINE
      parse_status_line line
    end

    @first_line_complete = true
  end

  def parse_request_line line
    @request = true
    @request_method, url, @http_version[0], @http_version[1] = line.scan(REQUEST_LINE).flatten
    @http_version.map! {|v| v.to_i}
    @uri = URI.parse url

    @callback.on_request_line self if @callback.respond_to?(:on_request_line)
  end

  def parse_status_line line
    @response = true
    @http_version[0], @http_version[1], code, @status_phrase = line.scan(STATUS_LINE).flatten
    @http_version.map! {|v| v.to_i}
    @status_code = code.to_i

    @callback.on_status_line self if @callback.respond_to?(:on_status_line)
  end

  def read_headers data
    while !data.eof? && !@headers_complete
      line = read data
      if line.empty?
        @headers_complete = true
      else
        key, value = line.split(":")
        @headers[key.downcase] = value.strip
        @header_orders << key.downcase
      end
    end

    @callback.on_headers_complete self if @callback.respond_to?(:on_headers_complete) && @headers_complete
  end

  def read_body data
    if headers.key? 'content-length'
      parse_body data
    elsif headers['content-encoding'] == 'chunked'
      parse_chunked_data data
    end
  end

  def parse_body data
    @body = read data, headers['content-length'].to_i
    @callback.on_body @body if @callback.respond_to?(:on_body)
    @body_complete = true
  end

  def parse_chunked_data data
    while !data.eof? && !@body_complete
      chunk_size = read(data).to_i
      if chunk_size == 0
        @body_complete = true
      else
        chunk = read(data, chunk_size)
        @body << chunk
        @callback.on_body chunk if @callback.respond_to?(:on_body)
      end
    end
  end
end