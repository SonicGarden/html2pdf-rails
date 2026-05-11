# frozen_string_literal: true

module Html2Pdf
  module Rails
    module MailerRendering
      def render_to_pdf_string(template: nil, layout: false, formats: [:pdf], handlers: nil, pdf_options: {})
        template ||= File.join(self.class.mailer_name, action_name)
        render_opts = { template: template, layout: layout, formats: formats }
        render_opts[:handlers] = handlers if handlers
        html = render_to_string(**render_opts)
        Html2Pdf::Rails.generate(html: html, pdf_options: pdf_options)
      end
    end
  end
end
