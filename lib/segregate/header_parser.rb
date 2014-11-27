require 'segregate/header_parser/http_headers'

class Segregate
  # HeaderParser
  class HeaderParser
    attr_reader :state, :body_type

    def method_missing(meth, *args, &block)
      if @headers.respond_to? meth
        @headers.send meth, *args, &block
      else
        super
      end
    end

    def respond_to?(meth, include_private = false)
      @headers.respond_to?(meth, include_private) || super
    end

    def initialize(log)
      @log             = log
      @state           = :ready
      @body_type       = :none
      @headers         = Hashie::Mash.new
      @header_order    = []
      @incomplete_data = ''
    end

    def parse_data(data)
      @log.debug "Parsing header data: #{data.string}"

      while !data.eof? && @state != :done
        line = read_line_from(data)
        break if line.nil?
        parse_header line
      end
    end

    def to_s
      temp_headers = ''
      @header_order.each do |header|
        temp_headers << header
        temp_headers << ': '
        temp_headers << @headers[header]
        temp_headers << "\r\n"
      end
      temp_headers << "\r\n"
      temp_headers
    end

    private

    def read_line_from(data)
      line = data.readline("\r\n")
      if line.end_with?("\r\n")
        line =  @incomplete_data + line.chomp
        @incomplete_data.clear
        return line
      else
        @log.debug "Incomplete Header: #{line}"
        @incomplete_data += line
        return nil
      end
    end

    def parse_header(line)
      @log.debug "Parsing header line: #{line}"
      if line.empty?
        @state = :done
        set_body_type
        @log.debug 'Headers Complete'
      else
        key, value = line.split(': ', 2)
        @header_order << key.downcase
        @headers[key.downcase] = value
        @log.debug "Parsed Header: #{key}: #{value}"
      end
    end

    def set_body_type
      if @headers['content-length'] && @headers['content-length'].to_i > 0
        @body_type = :length
      elsif @headers['transfer-encoding'] && @headers['transfer-encoding'] == 'chunked'
        @body_type = :chunked
      else
        @log.debug 'Body type: none'
        @log.warn 'No body type defined'
        @body_type = :none
      end
    end
  end
end
