# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Html2Pdf::Rails do
  describe '.generate' do
    let(:html) { '<html><body>hi</body></html>' }
    let(:pdf_bytes) { "%PDF-1.4\nbinary".b }

    it 'returns the PDF bytes from Client.post' do
      received_args = nil
      allow(Html2Pdf::Rails::Client).to receive(:post) do |**kwargs|
        received_args = kwargs
        pdf_bytes
      end

      result = described_class.generate(html: html, pdf_options: { margin: { top: '30px' } })

      expect(result).to eq(pdf_bytes)
      expect(received_args).to include(html: html, pdf_options: { margin: { top: '30px' } })
    end

    it 'defaults pdf_options to an empty hash and put_to_storage to false' do
      received_args = nil
      allow(Html2Pdf::Rails::Client).to receive(:post) do |**kwargs|
        received_args = kwargs
        pdf_bytes
      end

      described_class.generate(html: html)

      expect(received_args).to include(
        html: html,
        pdf_options: {},
        put_to_storage: false,
        file_name: nil,
        disposition: nil
      )
    end

    it 'forwards put_to_storage, file_name, and disposition to Client.post' do
      received_args = nil
      allow(Html2Pdf::Rails::Client).to receive(:post) do |**kwargs|
        received_args = kwargs
        '{"url":"https://example.com/x.pdf"}'
      end

      result = described_class.generate(
        html: html,
        pdf_options: { format: 'A4' },
        put_to_storage: true,
        file_name: 'x.pdf',
        disposition: 'attachment'
      )

      expect(result).to eq('{"url":"https://example.com/x.pdf"}')
      expect(received_args).to include(
        html: html,
        pdf_options: { format: 'A4' },
        put_to_storage: true,
        file_name: 'x.pdf',
        disposition: 'attachment'
      )
    end

    it 'retries on ServiceUnavailableError up to 3 times' do
      require 'net/http'
      response = instance_double(Net::HTTPResponse, code: '503')
      call_count = 0
      allow(Html2Pdf::Rails::Client).to receive(:post) do
        call_count += 1
        raise Html2Pdf::Rails::ServiceUnavailableError.new(response) if call_count < 3
        pdf_bytes
      end

      result = described_class.generate(html: html)

      expect(result).to eq(pdf_bytes)
      expect(call_count).to eq(3)
    end
  end
end
