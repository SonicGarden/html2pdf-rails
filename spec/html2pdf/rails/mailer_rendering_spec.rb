# frozen_string_literal: true

require 'spec_helper'
require 'action_mailer'

class TestMailer < ActionMailer::Base
  self.view_paths = [File.expand_path('../../fixtures/views', __dir__)]
  self.delivery_method = :test

  def notify(name, **opts)
    @name = name
    attachments['notify.pdf'] = render_to_pdf_string(**opts)
    mail(to: 'to@example.com', from: 'from@example.com', subject: 'subject')
  end
end

RSpec.describe Html2Pdf::Rails::MailerRendering do
  let(:pdf_bytes) { "%PDF-1.4\nbinary".b }
  let(:captured_html) { [] }

  before do
    Html2Pdf.configure { |c| c.endpoint = 'https://example.com/pdf' }
    allow(Html2Pdf::Rails::Client).to receive(:post) do |html:, **|
      captured_html << html
      pdf_bytes
    end
  end

  describe '#render_to_pdf_string with default options' do
    it 'returns the PDF bytes generated from the auto-detected template' do
      mail = TestMailer.notify('World').deliver_now

      expect(mail.attachments['notify.pdf']).not_to be_nil
      expect(mail.attachments['notify.pdf'].body.decoded).to eq(pdf_bytes)
    end

    it 'renders the .pdf.erb template (not .html.erb or .text.erb)' do
      TestMailer.notify('World').deliver_now

      expect(captured_html.last).to include('PDF template: Hello World!')
      expect(captured_html.last).not_to include('HTML template')
      expect(captured_html.last).not_to include('Email body text')
    end
  end

  describe 'overriding formats' do
    it 'renders the .html.erb template when formats: [:html] is passed' do
      TestMailer.notify('World', formats: [:html]).deliver_now

      expect(captured_html.last).to include('HTML template: Hello World!')
    end
  end

  describe 'overriding template' do
    it 'renders the specified template' do
      TestMailer.notify('World', template: 'test_mailer/custom').deliver_now

      expect(captured_html.last).to include('Custom template body')
    end
  end

  describe 'passing pdf_options through' do
    it 'forwards pdf_options to Html2Pdf::Rails.generate' do
      received = nil
      allow(Html2Pdf::Rails::Client).to receive(:post) do |**kwargs|
        received = kwargs
        pdf_bytes
      end

      TestMailer.notify('World', pdf_options: { margin: { top: '30px' } }).deliver_now

      expect(received).to include(pdf_options: { margin: { top: '30px' } })
    end
  end
end
