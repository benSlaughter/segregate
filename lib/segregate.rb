require 'lumberjack'
require 'juncture'
require 'hashie'
require 'uri'
require 'pry'

require 'segregate/first_line_parser'
require 'segregate/header_parser'
require 'segregate/body_length_parser'
require 'segregate/body_chunked_parser'

# Segregate
class Segregate
  extend Forwardable

  attr_reader :first_line, :headers, :state

  def method_missing(meth, *args, &block)
    if @first_line.respond_to? meth
      @first_line.send meth, *args, &block
    elsif @headers.respond_to? meth
      @headers.send meth, *args, &block
    elsif @body.respond_to? meth
      @body.send meth, *args, &block
    else
      super
    end
  end

  def respond_to?(meth, include_private = false)
    @first_line.respond_to?(meth, include_private) ||
    @headers.respond_to?(meth, include_private) ||
    @body.respond_to?(meth, include_private) ||
    super
  end

  def initialize(callback = nil)
    @log        = Lumberjack::Logger.new('./segregate.log', level: 0)
    @first_line = FirstLineParser.new @log
    @headers    = HeaderParser.new @log
    @callback   = callback
    @body       = nil
    @state      = :first_line
    p 'segregate initalised'
  end

  def body
    @body ? @body.body_data : nil
  end

  def body=(value)
    @body.body_data = value
  end

  def parse_data(data)
    data = StringIO.new(data)
    @log.debug "---parse_data---\n" + data.string
    while !data.eof? && @state != :done
      if @first_line.state != :done
        @first_line.parse_data(data)
        @state = :headers if @first_line.state == :done
      elsif @headers.state != :done
        @headers.parse_data(data)
        if @headers.state == :done
          @state = :body
          set_body
        end
      else
        @body.parse_data(data)
        @state = :done if @body.state == :done
        if @callback.respond_to?(:on_message_complete) && @body.state == :done
          @callback.on_message_complete self
        end
      end
    end
  end

  def to_s
    @headers['content-length'] = @body.body_data.length.to_s if @headers.body_type == :length
    @first_line.to_s + @headers.to_s + (@body ? @body.to_s : '') + "\r\n"
  end

  private

  def set_body
    case @headers.body_type
    when :length
      @body = BodyLengthParser.new @headers['content-length'], @log
    when :chunked
      @body = BodyChunkedParser.new @log
    else
      @log.error "Unknown body Type: #{@headers.body_type}"
      @state = :done
      @callback.on_message_complete self if @callback.respond_to?(:on_message_complete)
    end
  end
end
