# frozen_string_literal: true

require 'html2pdf/rails/client'

module Html2Pdf
  module Rails
    module Rendering
      def render_to_pdf(options)
        make_and_send_pdf(options.delete(:pdf), options)
      end

      private

      def make_and_send_pdf(pdf_name, options = {})
        options[:layout] ||= false
        options[:template] ||= File.join(controller_path, action_name)
        options[:disposition] ||= 'inline'
        options[:pdf_options] ||= {}

        if options[:show_as_html]
          render_opts = options.slice(:template, :layout, :formats, :handlers)
          render(render_opts.merge({ content_type: 'text/html' }))
        else
          pdf_content = make_pdf(options)
          send_data(pdf_content, filename: pdf_name + '.pdf', type: 'application/pdf', disposition: options[:disposition])
        end
      end

      def make_pdf(options = {})
        render_opts = options.slice(:template, :layout, :formats, :handlers)
        html = render_to_string(render_opts)
        Client.post(html, options[:pdf_options]).body
      end
    end
  end
end
