require 'uri'
require 'segregate/http_methods'
require 'segregate/http_regular_expressions'

class Segregate
  attr_reader :uri, :request_method, :status_code, :status_phrase, :http_version

  def initialize
    @uri = nil
    @request_method = nil
    @status_code = nil
    @status_phrase = nil
    @http_version = [nil, nil]

    @request = false
    @response = false

    @first_line_complete = false
    @headers_complete = false
    @body_complete = false
  end

  def request?
    @request
  end

  def response?
    @response
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

  def minor_http_version
    http_version[1]
  end

  def parse data
    raise "ERROR: parsing completed" if @body_complete

    data = StringIO.new data

    read_first_line data unless @first_line_complete
    read_headers data unless @headers_complete
    read_body data unless data.eof?
  end

  private

  def read data
    data.readline.chomp("\r\n")
  end

  def read_first_line data
    line = read data

    if line =~ REQUEST_LINE
      @request = true
      @request_method, url, @http_version[0], @http_version[1] = line.scan(REQUEST_LINE).flatten
      
      @http_version.map! {|v| v.to_i}
      @uri = URI.parse url

    elsif line =~ STATUS_LINE
      @response = true
      @http_version[0], @http_version[1], code, @status_phrase = line.scan(STATUS_LINE).flatten

      @http_version.map! {|v| v.to_i}
      @status_code = code.to_i

    elsif line =~ UNKNOWN_REQUEST_LINE
      raise "ERROR: Unknown http method: %s" % line[/^\S+/]

    else
      raise "ERROR: Unknown first line: %s" % line

    end

    @first_line_complete = true
  end

  def read_headers data
  end

  def read_body data
  end
end