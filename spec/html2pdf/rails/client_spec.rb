# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require 'json'

RSpec.describe Html2Pdf::Rails::Client do
  let(:endpoint) { 'https://example.com/html2pdf' }
  let(:http) { instance_double(Net::HTTP) }
  let(:response) { instance_double(Net::HTTPResponse, code: response_code, body: response_body) }
  let(:response_code) { '200' }
  let(:response_body) { 'pdf-bytes' }
  let(:captured_request) { [] }

  before do
    Html2Pdf.configure { |c| c.endpoint = endpoint }
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:request) do |request|
      captured_request << request
      response
    end
  end

  describe '.post' do
    it 'returns the response body on 200' do
      result = described_class.post(html: '<html></html>', pdf_options: {})

      expect(result).to eq('pdf-bytes')
    end

    it 'sends the configured endpoint host and port to Net::HTTP.new' do
      described_class.post(html: '<html></html>', pdf_options: {})

      expect(Net::HTTP).to have_received(:new).with('example.com', 443)
    end

    it 'enables SSL for https endpoints' do
      described_class.post(html: '<html></html>', pdf_options: {})

      expect(http).to have_received(:use_ssl=).with(true)
    end

    context 'when endpoint is http' do
      let(:endpoint) { 'http://example.com/html2pdf' }

      it 'disables SSL' do
        described_class.post(html: '<html></html>', pdf_options: {})

        expect(http).to have_received(:use_ssl=).with(false)
      end
    end

    it 'sends a JSON body with the expected keys' do
      described_class.post(
        html: '<html>x</html>',
        put_to_storage: true,
        file_name: 'foo.pdf',
        disposition: 'attachment',
        pdf_options: { margin: { top: '10px' } }
      )

      body = JSON.parse(captured_request.first.body)
      expect(body).to eq(
        'app' => nil,
        'html' => '<html>x</html>',
        'putToStorage' => true,
        'fileName' => 'foo.pdf',
        'responseDisposition' => 'attachment',
        'pdfOptions' => { 'margin' => { 'top' => '10px' } }
      )
    end

    it 'sends the configured app in the JSON body' do
      Html2Pdf.config.app = 'MyApp'

      described_class.post(html: '<html></html>', pdf_options: {})

      body = JSON.parse(captured_request.first.body)
      expect(body['app']).to eq('MyApp')
    ensure
      Html2Pdf.config.app = nil
    end

    it 'sets Content-Type header to application/json' do
      described_class.post(html: '<html></html>', pdf_options: {})

      expect(captured_request.first['Content-Type']).to eq('application/json')
    end

    describe 'Authorization header' do
      around do |example|
        original = ENV.delete('HTML2PDF_API_KEY')
        example.run
      ensure
        Html2Pdf.config.api_key = nil
        original.nil? ? ENV.delete('HTML2PDF_API_KEY') : ENV['HTML2PDF_API_KEY'] = original
      end

      it 'is not sent when no API key is configured' do
        described_class.post(html: '<html></html>', pdf_options: {})

        expect(captured_request.first['Authorization']).to be_nil
      end

      it 'sends the configured API key as a Bearer token' do
        Html2Pdf.config.api_key = 'sgh2p_configured'

        described_class.post(html: '<html></html>', pdf_options: {})

        expect(captured_request.first['Authorization']).to eq('Bearer sgh2p_configured')
      end

      it 'falls back to ENV["HTML2PDF_API_KEY"]' do
        ENV['HTML2PDF_API_KEY'] = 'sgh2p_from_env'

        described_class.post(html: '<html></html>', pdf_options: {})

        expect(captured_request.first['Authorization']).to eq('Bearer sgh2p_from_env')
      end

      it 'prefers the configured API key over ENV' do
        ENV['HTML2PDF_API_KEY'] = 'sgh2p_from_env'
        Html2Pdf.config.api_key = 'sgh2p_configured'

        described_class.post(html: '<html></html>', pdf_options: {})

        expect(captured_request.first['Authorization']).to eq('Bearer sgh2p_configured')
      end

      it 'is not sent when the API key is an empty string' do
        ENV['HTML2PDF_API_KEY'] = ''

        described_class.post(html: '<html></html>', pdf_options: {})

        expect(captured_request.first['Authorization']).to be_nil
      end
    end

    context 'when response is 401' do
      let(:response_code) { '401' }

      it 'raises UnauthorizedError, which is a RequestError' do
        expect {
          described_class.post(html: '<html></html>', pdf_options: {})
        }.to raise_error(Html2Pdf::Rails::UnauthorizedError, /api_key/) { |e|
          expect(e).to be_a(Html2Pdf::Rails::RequestError)
        }
      end

      it 'does not include the API key in the error message' do
        Html2Pdf.config.api_key = 'sgh2p_secret'

        expect {
          described_class.post(html: '<html></html>', pdf_options: {})
        }.to raise_error(Html2Pdf::Rails::UnauthorizedError) { |e| expect(e.message).not_to include('sgh2p_secret') }
      ensure
        Html2Pdf.config.api_key = nil
      end
    end

    context 'when response is 503' do
      let(:response_code) { '503' }

      it 'raises ServiceUnavailableError' do
        expect {
          described_class.post(html: '<html></html>', pdf_options: {})
        }.to raise_error(Html2Pdf::Rails::ServiceUnavailableError)
      end
    end

    context 'when response is some other error code' do
      let(:response_code) { '500' }

      it 'raises RequestError' do
        expect {
          described_class.post(html: '<html></html>', pdf_options: {})
        }.to raise_error(Html2Pdf::Rails::RequestError)
      end
    end

    context 'when http request raises Net::ReadTimeout' do
      before do
        allow(http).to receive(:request).and_raise(Net::ReadTimeout)
      end

      it 'raises NetworkError' do
        expect {
          described_class.post(html: '<html></html>', pdf_options: {})
        }.to raise_error(Html2Pdf::Rails::NetworkError)
      end
    end
  end
end
