require 'juncture'
require 'hashie'
require 'uri'
require 'segregate/version'
require 'segregate/http_methods'
require 'segregate/http_headers'
require 'segregate/http_regular_expressions'

class Segregate
  attr_reader :uri, :type, :state, :http_version, :headers
  attr_accessor :request_method, :status_code, :status_phrase, :body

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

  def debug message
    if @debug
      puts "DEBUG: " + message.to_s
    end
  end

  def initialize callback = nil, *args, **kwargs
    @debug = kwargs[:debug] ? true : false
    @callback = callback
    @http_version = [nil, nil]

    # :request, :response
    @type = Juncture.new :request, :response
    @state = Juncture.new :waiting, :headers, :body, :done, default: :waiting

    @headers = Hashie::Mash.new
    @body = ""

    @stashed_data = ""
    @stashed_body = ""

    @header_order = []
  end

  def request?
    @type == :request
  end

  def response?
    @type == :response
  end

  def headers_complete?
    @state > :headers
  end

  def done?
    @state >= :done
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

  def major_http_version= value
    http_version[0] = value
  end

  def minor_http_version
    http_version[1]
  end

  def minor_http_version= value
    http_version[1] = value
  end

  def update_content_length
    unless @body.empty?
      if @headers['content-length']
        @headers['content-length'] = @body.length.to_s
      end
    end
  end

  def raw_data
    raw_message = ""
    update_content_length

    build_headers raw_message
    build_body raw_message

    return raw_message
  end

  def build_headers raw_message
    request? ? raw_message << request_line + "\r\n" : raw_message << status_line + "\r\n"
    @header_order.each do |header|
      values = @headers[header.downcase]
      if values.kind_of?(Array)
        values.each do |value|
          raw_message << "%s: %s\r\n" % [header, value]
        end
      else
        raw_message << "%s: %s\r\n" % [header, values]
      end
    end
    raw_message << "\r\n"
  end

  def build_body raw_message
    new_body, size = deflate_if_needed(@body)
    if @headers['content-length']
      raw_message << new_body
      raw_message << "\r\n\r\n"
    elsif @headers['transfer-encoding'] == 'chunked'
      raw_message << "%s\r\n" % (size.to_s(16))
      raw_message << new_body + "\r\n"
      raw_message << "0\r\n\r\n"
    end
  end

  def deflate_if_needed(body)
    return [body, body.size] unless gzip_encoded_body?

    str_io = StringIO.new('w')
    w_gz = Zlib::GzipWriter.new(str_io)
    w_gz.write(body)
    w_gz.close

    # To specify the number of bytes for a gzip string
    # we should check for the buffer size instead of the string size
    [str_io.string, str_io.size]
  end

  def parse_data data
    data = StringIO.new(@stashed_data + data)
    @stashed_data = ""

    while !data.eof? && @state < :done
      line, complete_line = get_next_line data
      complete_line ? parse_line(line) : @stashed_data = line
    end

    data.close
  end

  def parse_line line
    case @state.state
    when :waiting
      read_in_first_line line
    when :headers
      read_in_headers line
    when :body
      read_in_body line
    end

    @callback.on_message_complete self if @callback.respond_to?(:on_message_complete) && done?
  end

  private

  def get_next_line data
    if @headers['content-length'] && @state >= :body
      line = data.readline("\r\n")
      @inital_line = line
      [line, true]
    else
      line = data.readline("\r\n")
      @inital_line = line
      result = line.end_with?("\r\n")
      line = line[0..-3] if result
      [line, result]
    end
  end

  def read_in_first_line line
    @callback.on_message_begin self if @callback.respond_to?(:on_message_begin)

    if line =~ REQUEST_LINE
      parse_request_line line
    elsif line =~ STATUS_LINE
      parse_status_line line
    else
      raise "ERROR: Unknown first line: %s" % line
    end

    @state.next
  end

  def parse_request_line line
    @type.set :request
    @request_method, url, @http_version[0], @http_version[1] = line.scan(REQUEST_LINE).flatten
    @http_version.map! {|v| v.to_i}
    @uri = URI.parse url

    @callback.on_request_line self if @callback.respond_to?(:on_request_line)
  end

  def parse_status_line line
    @type.set :response
    @http_version[0], @http_version[1], code, @status_phrase = line.scan(STATUS_LINE).flatten
    @http_version.map! {|v| v.to_i}
    @status_code = code.to_i

    @callback.on_status_line self if @callback.respond_to?(:on_status_line)
  end

  def read_in_headers line
    if line.empty?
      @state.next
    else
      key, value = line.split(": ",2)
      @header_order << key unless @header_order.include?(key)
      save_value(@headers, key, value)
    end

    if headers_complete?
      @callback.on_headers_complete self if @callback.respond_to?(:on_headers_complete)
      if headers['transfer-encoding'].nil? && (headers['content-length'] == "0" || headers['content-length'].nil?)
        @state.set :done
      end
    end
  end

  def read_in_body line
    if headers['content-length']
      parse_body line
    elsif headers['transfer-encoding'] == 'chunked'
      parse_chunked_data line
    end
  end

  def parse_body line
    line = @stashed_body + line
    @stashed_body = ""

    if line.length >= headers['content-length'].to_i
      # Removing delimiters characters from the HTTP protocol
      line = line[0..-3]
      @body = inflate_body_if_needed(line)
      @callback.on_body @body if @callback.respond_to?(:on_body)
      @state.next
    else
      @stashed_body = line
    end
  end

  def inflate_body_if_needed(body)
    return body unless gzip_encoded_body?

    gzip_str  = StringIO.new(body)
    gzip_body = Zlib::GzipReader.new( gzip_str )
    gzip_body.read()
  end

  def gzip_encoded_body?
    headers.key?('content-encoding') && headers['content-encoding'].eql?('gzip')
  end

  def parse_chunked_data line
    @chunked_body_state ||= Juncture.new :size, :chunk, default: :size

    case @chunked_body_state.state
    when :size
      parse_chunked_data_size line.to_i(16)
    when :chunk
      parse_chunked_data_chunk line
    end
  end

  def parse_chunked_data_size chunk_size
    if chunk_size == 0
      @state.next
    else
      @chunk_size = chunk_size
    end
    @chunked_body_state.next
  end

  def parse_chunked_data_chunk line
    line = @stashed_body + line
    @stashed_body = ""

    if line.length >= @chunk_size
      @body << line
      @original_body = @body
      @body = inflate_body_if_needed(@body)
      @callback.on_body line if @callback.respond_to?(:on_body)
      @chunked_body_state.next
    else
      @stashed_body = @inital_line.end_with?("\r\n") ? (line + "\r\n") : line
    end
  end

  def save_value(store_hash, key, value)
    key = key.downcase
    if store_hash.key?(key)
      store_hash[key] = [] << store_hash[key] unless store_hash[key].kind_of?(Array)
      store_hash[key] << value
    else
      store_hash[key] = value
    end
  end
end