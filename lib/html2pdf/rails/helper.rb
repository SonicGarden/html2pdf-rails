# frozen_string_literal: true

module Html2Pdf
  module Rails
    module Helper
      def html2pdf_base_tag(host: nil, protocol: nil)
        req = _html2pdf_request

        host ||= req && (req.headers['HTTP_X_ORIGINAL_HOST'] || req.host)
        host ||= Html2Pdf.config.default_host
        if host.nil? || host.empty?
          raise ArgumentError,
                'html2pdf_base_tag: host is not available. Pass `host:` or set Html2Pdf.config.default_host.'
        end

        protocol ||= req&.protocol
        protocol ||= Html2Pdf.config.default_protocol
        protocol ||= 'https'
        protocol = "#{protocol}://" unless protocol.end_with?('://')

        tag.base href: "#{protocol}#{host}"
      end

      private

      def _html2pdf_request
        respond_to?(:request) ? request : nil
      end
    end
  end
end
