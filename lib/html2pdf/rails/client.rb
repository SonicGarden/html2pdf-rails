# frozen_string_literal: true

require 'html2pdf/rails/errors'

module Html2Pdf
  module Rails
    class Client
      def self.post(*args)
        self.new(Html2Pdf.config.endpoint).post(*args)
      end

      def initialize(endpoint)
        @uri = URI.parse(endpoint)
      end

      def post(html:, storage_url: nil, put_to_storage: false, file_name: nil, disposition: null, pdf_options: {})
        http = Net::HTTP.new(@uri.host, @uri.port).tap { |h| h.use_ssl = @uri.scheme == 'https' }
        request = Net::HTTP::Post.new(@uri.request_uri, headers)
        request.body = {
          html: html,
          storageUrl: storage_url,
          putToStorage: put_to_storage,
          fileName: file_name,
          responseDisposition: disposition,
          pdfOptions: pdf_options
        }.to_json
        http.request(request)
      rescue Net::ReadTimeout
        raise Html2Pdf::Rails::NetworkError
      end

      private

      def headers
        { 'Content-Type' => 'application/json' }
      end
    end
  end
end
