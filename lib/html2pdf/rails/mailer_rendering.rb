# frozen_string_literal: true

module Html2Pdf
  module Rails
    module MailerRendering
      def render_to_pdf_string(template: nil, layout: false, formats: [:pdf], handlers: nil, pdf_options: {})
        # When :template is omitted, Rails resolves the template from `_prefixes`
        # (= [mailer_name]) and `action_name` via `_process_render_template_options`:
        # https://github.com/rails/rails/blob/v8.1.2/actionview/lib/action_view/rendering.rb#L177
        render_opts = { template: template, layout: layout, formats: formats, handlers: handlers }.compact
        html = render_to_string(**render_opts)
        Html2Pdf::Rails.generate(html: html, pdf_options: pdf_options)
      end
    end
  end
end
