# frozen_string_literal: true

require 'html2pdf/rails/client'

module Html2Pdf
  module Rails
    module Rendering
      def render_to_pdf(options)
        _html2pdf_make_and_send_pdf(options.delete(:pdf), options)
      end

      def render_pdf_and_get_url(options)
        _html2_pdf_render_pdf_and_get_url(options.delete(:pdf), options)
      end

      private

      def _html2pdf_default_options(pdf_name, options)
        new_options = options.dup
        new_options[:layout] ||= false
        new_options[:template] ||= File.join(controller_path, action_name)
        new_options[:pdf_options] ||= {}
        new_options[:file_name] = "#{pdf_name}.pdf"
        new_options[:disposition] ||= 'inline'
        new_options
      end

      def _html2_pdf_render_pdf_and_get_url(pdf_name, options = {})
        options = _html2pdf_default_options(pdf_name, options)
        options[:put_to_storage] = true
        json = JSON.parse _html2pdf_make_pdf(options)
        json['url']
      end

      def _html2pdf_make_and_send_pdf(pdf_name, options = {})
        options = _html2pdf_default_options(pdf_name, options)

        if options[:show_as_html]
          render_opts = options.slice(:template, :layout, :formats, :handlers)
          render(render_opts.merge({ content_type: 'text/html' }))
        else
          pdf_content = _html2pdf_make_pdf(options)
          send_data(pdf_content, filename: options[:file_name], type: 'application/pdf', disposition: options[:disposition])
        end
      end

      def _html2pdf_make_pdf(options = {})
        render_opts = options.slice(:template, :layout, :formats, :handlers)
        html = render_to_string(render_opts)
        response = Client.post(
          html: html,
          put_to_storage: options[:put_to_storage],
          file_name: options[:file_name],
          disposition: options[:disposition],
          pdf_options: options[:pdf_options]
        )
        case response.code
        when '200'
          response.body
        else
          raise Html2Pdf::Rails::RequestError.new(response)
        end
      end
    end
  end
end
