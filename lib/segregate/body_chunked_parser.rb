class Segregate
  # BodyChunkedParser
  class BodyChunkedParser
    attr_reader :state
    attr_accessor :body_data

    def initialize(log)
      @log             = log
      @state           = :ready
      @body_data       = ''
      @incomplete_data = ''
      @chunk_size      = nil
      @stashed_body    = ''

      @log.debug 'Body type defined: chunked'
    end

    def parse_data(data)
      @log.debug "Parsing body data: #{data.string}"

      while !data.eof? && @state != :done
        line = read_line_from(data)
        break if line.nil?
        parse_chunked_data line
      end
    end

    def to_s
      temp_body = ''
      @body_data.chars.each_slice(10_240).map(&:join).each do |chunk|
        temp_body << chunk.length.to_s(16) + "\r\n"
        temp_body << chunk + "\r\n"
      end
      temp_body << "0\r\n"
    end

    private

    def read_line_from(data)
      line = data.readline("\r\n")
      if line.end_with?("\r\n")
        line =  @incomplete_data + line.chomp
        @incomplete_data.clear
        return line
      else
        @log.debug "Incomplete Body chunk: #{line}"
        @incomplete_data += line
        return nil
      end
    end

    def parse_chunked_data(line)
      @chunked_body_state ||= Juncture.new :size, :chunk, default: :size

      case @chunked_body_state.state
      when :size
        parse_chunked_data_size line.to_i(16)
      when :chunk
        parse_chunked_data_chunk line
      end
    end

    def parse_chunked_data_size(chunk_size)
      if chunk_size == 0
        @state = :done
      else
        @chunk_size = chunk_size
      end
      @chunked_body_state.next
    end

    def parse_chunked_data_chunk(line)
      line = @stashed_body + line
      @stashed_body.clear

      if line.length >= @chunk_size
        @body_data << line
        @chunked_body_state.next
      else
        @stashed_body = line
      end
    end
  end
end
