require 'segregate/first_line_parser/first_line_helpers'

class Segregate
  # FirstLineParser
  class FirstLineParser
    include FirstLineHelpers
    attr_reader :state, :type, :http_version, :uri
    attr_accessor :status_code, :status_phrase, :request_method

    def method_missing(meth, *args, &block)
      if @uri.respond_to? meth
        @uri.send meth, *args, &block
      else
        super
      end
    end

    def respond_to?(meth, include_private = false)
      @uri.respond_to?(meth, include_private) || super
    end

    def initialize(log)
      @log             = log
      @state           = :ready
      @type            = :unknown
      @http_version    = [nil, nil]
      @status_code     = nil
      @status_phrase   = nil
      @request_method  = nil
      @uri             = nil
      @incomplete_data = ''
      @unknown_line    = nil
    end

    def parse_data(data)
      @log.debug "Parsing First line data: #{data.string}"

      while !data.eof? && @state != :done
        line = read_line_from(data)
        break if line.nil?
        parse_first_line line
      end
    end

    def to_s
      case @type
      when :request
        request_line + "\r\n"
      when :response
        status_line + "\r\n"
      else
        @unknown_line ? @unknown_line + "\r\n" : ''
      end
    end

    private

    def read_line_from(data)
      line = data.readline("\r\n")
      if line.end_with?("\r\n")
        line =  @incomplete_data + line.chomp
        @incomplete_data.clear
        return line
      else
        @log.debug "Incomplete First line: #{line}"
        @incomplete_data += line
        return nil
      end
    end

    def parse_first_line(line)
      @log.debug "Parsing First line: #{line}"
      if line =~ REQUEST_LINE
        @type = :request
        parse_request_line line
      elsif line =~ STATUS_LINE
        @type = :response
        parse_status_line line
      else
        @type = :unknown
        @log.error "Unknown First line: #{line}"
        @unknown_line = line
      end
      @state = :done
      @log.debug 'First line Complete'
    end

    def parse_request_line(line)
      @log.debug "Parsing Request line: #{line}"

      @request_method, url, @http_version[0], @http_version[1] = line.scan(REQUEST_LINE).flatten
      @http_version.map! { |v| v.to_i }
      @uri = URI.parse url

      return unless HTTP_METHODS.include? @request_method
      @log.warn "Unknown Request method: #{@request_method}"
    end

    def parse_status_line(line)
      @log.debug "Parsing Status line: #{line}"
      @http_version[0], @http_version[1], code, @status_phrase = line.scan(STATUS_LINE).flatten
      @http_version.map! { |v| v.to_i }
      @status_code = code.to_i
    end
  end
end
