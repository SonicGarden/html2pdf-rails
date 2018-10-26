# frozen_string_literal: true

module Html2Pdf
  module Rails
    module Helper
      def html2pdf_base_tag
        # NOTE: for Ngrok
        host = request.headers['HTTP_X_ORIGINAL_HOST'] || request.host
        base_url = "#{request.protocol}#{host}"
        tag.base href: base_url
      end
    end
  end
end
