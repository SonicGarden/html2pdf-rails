module Html2Pdf
  module Rails
    class NetworkError < StandardError
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
  end
end
