module Html2Pdf
  module Rails
    class NetworkError < StandardError
    end

    # Raised when the configured API key cannot be sent as a header value.
    class InvalidApiKeyError < ArgumentError
    end

    class RequestError < StandardError
      attr_reader :response

      def initialize(response, msg = nil)
        msg ||= "html2pdf request failed and got HTTP status #{response.code}"
        super(msg)
        @response = response
      end
    end

    class ServiceUnavailableError < RequestError
    end

    # Raised on HTTP 401. Not retried, because sending the same API key again cannot succeed.
    class UnauthorizedError < RequestError
      def initialize(response, msg = nil)
        msg ||= 'html2pdf request was rejected with HTTP status 401. ' \
                'Check that Html2Pdf.config.api_key (or ENV["HTML2PDF_API_KEY"]) is set to a valid key.'
        super(response, msg)
      end
    end
  end
end
