# frozen_string_literal: true

module Html2Pdf
  module Rails
    class Client
      def self.post(*args)
        self.new(Html2Pdf.config.endpoint).post(*args)
      end

      def initialize(endpoint)
        @uri = URI.parse(endpoint)
      end

      def post(html:, storage_url: nil, pdf_options: {})
        http = Net::HTTP.new(@uri.host, @uri.port).tap { |h| h.use_ssl = @uri.scheme == 'https' }
        request = Net::HTTP::Post.new(@uri.request_uri, headers)
        request.body = { html: html, storageUrl: storage_url, pdfOptions: pdf_options }.to_json
        http.request(request)
      end

      private

      def headers
        { 'Content-Type' => 'application/json' }
      end
    end
  end
end
