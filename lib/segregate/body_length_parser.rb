class Segregate
  # BodyLengthParser
  class BodyLengthParser
    attr_reader :state
    attr_accessor :body_data

    def initialize(content_length, log)
      @content_length  = content_length
      @log             = log
      @state           = :ready
      @body_data       = ''

      @log.debug 'Body type defined: length'
    end

    def parse_data(data)
      @log.debug "Parsing body data: #{data.string}"

      while !data.eof? && @state != :done
        line = data.readline("\r\n")
        @body_data << line

        if body_data.length >= @content_length.to_i
          @body_data.chomp!
          @state = :done
          @log.debug 'Body Complete'
        end
      end
    end

    def to_s
      @body_data + "\r\n"
    end
  end
end
