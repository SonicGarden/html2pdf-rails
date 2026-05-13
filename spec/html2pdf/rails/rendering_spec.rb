# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Html2Pdf::Rails::Rendering do
  let(:controller_class) do
    Class.new do
      include Html2Pdf::Rails::Rendering

      attr_reader :rendered_render, :sent_data, :rendered_html_opts

      def controller_path
        'things'
      end

      def action_name
        'show'
      end

      def render_to_string(**opts)
        @rendered_html_opts = opts
        '<html>body</html>'
      end

      def render(opts)
        @rendered_render = opts
      end

      def send_data(content, opts)
        @sent_data = { content: content, opts: opts }
      end
    end
  end

  let(:controller) { controller_class.new }
  let(:pdf_bytes) { "%PDF-1.4\nbinary".b }

  before do
    allow(Html2Pdf::Rails::Client).to receive(:post).and_return(pdf_bytes)
  end

  describe '#render_to_pdf' do
    it 'sends PDF bytes via send_data with the configured filename' do
      controller.render_to_pdf(pdf: 'invoice')

      expect(controller.sent_data[:content]).to eq(pdf_bytes)
      expect(controller.sent_data[:opts]).to include(
        filename: 'invoice.pdf',
        type: 'application/pdf',
        disposition: 'inline'
      )
    end

    it 'allows overriding disposition' do
      controller.render_to_pdf(pdf: 'invoice', disposition: 'attachment')

      expect(controller.sent_data[:opts]).to include(disposition: 'attachment')
    end

    it 'infers the template from controller_path and action_name by default' do
      controller.render_to_pdf(pdf: 'invoice')

      expect(controller.rendered_html_opts).to include(template: 'things/show', layout: false)
    end

    it 'allows overriding template and layout' do
      controller.render_to_pdf(pdf: 'invoice', template: 'custom/template', layout: 'pdf')

      expect(controller.rendered_html_opts).to include(template: 'custom/template', layout: 'pdf')
    end

    it 'passes pdf_options through to Html2Pdf::Rails.generate' do
      received = nil
      allow(Html2Pdf::Rails::Client).to receive(:post) do |**kwargs|
        received = kwargs
        pdf_bytes
      end

      controller.render_to_pdf(pdf: 'invoice', pdf_options: { margin: { top: '10px' } })

      expect(received).to include(html: '<html>body</html>', pdf_options: { margin: { top: '10px' } })
    end

    context 'when show_as_html is truthy' do
      it 'renders HTML and does not call the PDF service' do
        controller.render_to_pdf(pdf: 'invoice', show_as_html: true)

        expect(controller.rendered_render).to include(content_type: 'text/html')
        expect(Html2Pdf::Rails::Client).not_to have_received(:post)
        expect(controller.sent_data).to be_nil
      end
    end
  end

  describe '#render_pdf_and_get_url' do
    before do
      allow(Html2Pdf::Rails::Client).to receive(:post).and_return('{"url":"https://example.com/signed.pdf"}')
    end

    it 'returns the signed url from the JSON response' do
      result = controller.render_pdf_and_get_url(pdf: 'invoice')

      expect(result).to eq('https://example.com/signed.pdf')
    end

    it 'calls Client.post with put_to_storage: true' do
      received = nil
      allow(Html2Pdf::Rails::Client).to receive(:post) do |**kwargs|
        received = kwargs
        '{"url":"https://example.com/signed.pdf"}'
      end

      controller.render_pdf_and_get_url(pdf: 'invoice', pdf_options: { format: 'A4' })

      expect(received).to include(
        html: '<html>body</html>',
        put_to_storage: true,
        file_name: 'invoice.pdf',
        disposition: 'inline',
        pdf_options: { format: 'A4' }
      )
    end
  end
end
