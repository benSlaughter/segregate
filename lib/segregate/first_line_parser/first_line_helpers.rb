class Segregate
  class FirstLineParser
    # FirstLineHelpers
    module FirstLineHelpers
      HTTP_METHODS = %w('OPTIONS GET HEAD POST PUT DELETE TRACE CONNECT PATCH')
      REQUEST_LINE = /^([A-Z]+)\s(\*|\S+)\sHTTP\/(\d)\.(\d)$/
      STATUS_LINE = /^HTTP\/(\d).(\d)\s(\d{3})\s(.+)$/

      def request?
        @type == :request
      end

      def response?
        @type == :response
      end

      def unknown?
        @type == :unknown
      end

      def request_line
        if request?
          "#{request_method} #{request_url} HTTP/#{major_http_version}.#{minor_http_version}"
        else
          nil
        end
      end

      def status_line
        if response?
          "HTTP/#{major_http_version}.#{minor_http_version} #{status_code} #{status_phrase}"
        else
          nil
        end
      end

      def unknown_line
        if unknown?
          @unknown_line
        else
          nil
        end
      end

      def request_url
        @uri ? @uri.to_s : nil
      end

      def major_http_version
        @http_version[0]
      end

      def major_http_version=(value)
        @http_version[0] = value
      end

      def minor_http_version
        @http_version[1]
      end

      def minor_http_version=(value)
        @http_version[1] = value
      end
    end
  end
end
