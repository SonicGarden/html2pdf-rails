# frozen_string_literal: true

require 'html2pdf/rails/client'
require 'html2pdf/rails/s3'

module Html2Pdf
  module Rails
    module Rendering
      def render_to_pdf(options)
        _html2pdf_make_and_send_pdf(options.delete(:pdf), options)
      end

      def render_pdf_to_s3(options)
        _html2pdf_render_pdf_to_s3(options.delete(:pdf), options)
      end

      private

      def _html2pdf_default_options(options)
        new_options = options.dup
        new_options[:layout] ||= false
        new_options[:template] ||= File.join(controller_path, action_name)
        new_options[:pdf_options] ||= {}
        new_options
      end

      def _html2pdf_render_pdf_to_s3(pdf_name, options = {})
        disposition = options[:disposition] || 'inline'
        file_name = "#{pdf_name}.pdf"
        options = _html2pdf_default_options(options)
        options[:storage_url] = ::Html2Pdf::Rails::S3.presigned_put_url(file_name)

        _html2pdf_make_pdf(options)
        ::Html2Pdf::Rails::S3.presigned_get_url(file_name, disposition: disposition)
      end

      def _html2pdf_make_and_send_pdf(pdf_name, options = {})
        disposition = options[:disposition] || 'inline'
        options = _html2pdf_default_options(options)

        if options[:show_as_html]
          render_opts = options.slice(:template, :layout, :formats, :handlers)
          render(render_opts.merge({ content_type: 'text/html' }))
        else
          pdf_content = _html2pdf_make_pdf(options)
          send_data(pdf_content, filename: pdf_name + '.pdf', type: 'application/pdf', disposition: disposition)
        end
      end

      def _html2pdf_make_pdf(options = {})
        render_opts = options.slice(:template, :layout, :formats, :handlers)
        html = render_to_string(render_opts)
        Client.post(html: html, storage_url: options[:storage_url], pdf_options: options[:pdf_options]).body
      end
    end
  end
end
