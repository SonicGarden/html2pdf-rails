# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Html2Pdf::Rails::MailerRendering do
  let(:mailer_class) do
    Class.new do
      include Html2Pdf::Rails::MailerRendering

      def self.mailer_name
        'order_mailer'
      end

      attr_accessor :action_name, :render_to_string_calls

      def initialize(action_name)
        @action_name = action_name
        @render_to_string_calls = []
      end

      def render_to_string(**opts)
        @render_to_string_calls << opts
        '<html>rendered</html>'
      end
    end
  end

  let(:mailer) { mailer_class.new('receipt') }
  let(:pdf_bytes) { "%PDF-1.4\nbinary".b }

  before do
    allow(Html2Pdf::Rails::Client).to receive(:post).and_return(pdf_bytes)
  end

  it 'returns the PDF bytes' do
    expect(mailer.render_to_pdf_string).to eq(pdf_bytes)
  end

  it 'auto-detects template from mailer_name and action_name' do
    mailer.render_to_pdf_string

    expect(mailer.render_to_string_calls.last).to include(template: 'order_mailer/receipt')
  end

  it 'defaults formats to [:pdf]' do
    mailer.render_to_pdf_string

    expect(mailer.render_to_string_calls.last).to include(formats: [:pdf])
  end

  it 'defaults layout to false' do
    mailer.render_to_pdf_string

    expect(mailer.render_to_string_calls.last).to include(layout: false)
  end

  it 'allows overriding template, layout, and formats' do
    mailer.render_to_pdf_string(template: 'custom/path', layout: 'pdf', formats: [:html])

    expect(mailer.render_to_string_calls.last).to include(
      template: 'custom/path',
      layout: 'pdf',
      formats: [:html]
    )
  end

  it 'passes pdf_options through to Html2Pdf::Rails.generate' do
    received_args = nil
    allow(Html2Pdf::Rails::Client).to receive(:post) do |**kwargs|
      received_args = kwargs
      pdf_bytes
    end

    mailer.render_to_pdf_string(pdf_options: { margin: { top: '30px' } })

    expect(received_args).to include(html: '<html>rendered</html>', pdf_options: { margin: { top: '30px' } })
  end
end
