# frozen_string_literal: true

module Html2Pdf
  module Rails
    class Client
      def self.post(*args)
        self.new(::Rails.application.config.html2pdf_rails.endpoint).post(*args)
      end

      def initialize(endpoint)
        @uri = URI.parse(endpoint)
      end

      def post(html, pdf_options = {})
        http = Net::HTTP.new(@uri.host, @uri.port).tap { |h| h.use_ssl = @uri.scheme == 'https' }
        request = Net::HTTP::Post.new(@uri.request_uri, headers)
        request.body = { html: html, pdfOptions: pdf_options }.to_json
        http.request(request)
      end

      private

      def headers
        { 'Content-Type' => 'application/json' }
      end
    end
  end
end
