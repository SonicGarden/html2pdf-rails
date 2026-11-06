# frozen_string_literal: true

require 'html2pdf/rails/errors'

module Html2Pdf
  module Rails
    class Client
      def self.post(**options)
        self.new(Html2Pdf.config.endpoint, Html2Pdf.config.app, api_key: Html2Pdf.config.api_key).post(**options)
      end

      def initialize(endpoint, app, api_key: nil)
        @uri = URI.parse(endpoint)
        @app = app
        @api_key = api_key
      end

      def post(html:, put_to_storage: false, file_name: nil, disposition: nil, pdf_options: {})
        http = Net::HTTP.new(@uri.host, @uri.port).tap { |h| h.use_ssl = @uri.scheme == 'https' }
        request = Net::HTTP::Post.new(@uri.request_uri, headers)
        request.body = {
          app: @app,
          html: html,
          putToStorage: put_to_storage,
          fileName: file_name,
          responseDisposition: disposition,
          pdfOptions: pdf_options
        }.to_json
        response = http.request(request)

        case response.code
        when '200'
          response.body
        when '401'
          raise Html2Pdf::Rails::UnauthorizedError.new(response)
        when '503'
          raise Html2Pdf::Rails::ServiceUnavailableError.new(response)
        else
          raise Html2Pdf::Rails::RequestError.new(response)
        end
      rescue Net::ReadTimeout
        raise Html2Pdf::Rails::NetworkError
      end

      private

      def headers
        headers = { 'Content-Type' => 'application/json' }
        headers['Authorization'] = "Bearer #{@api_key}" if @api_key && !@api_key.empty?
        headers
      end
    end
  end
end
