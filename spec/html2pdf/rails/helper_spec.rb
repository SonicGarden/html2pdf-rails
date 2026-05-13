# frozen_string_literal: true

require 'spec_helper'
require 'action_view'

RSpec.describe Html2Pdf::Rails::Helper do
  let(:view_class) do
    Class.new do
      include ActionView::Helpers::TagHelper
      include Html2Pdf::Rails::Helper

      attr_accessor :request
      attr_writer :stubbed_url_options

      def url_options
        @stubbed_url_options || {}
      end

      def output_buffer
        @output_buffer ||= ActionView::OutputBuffer.new
      end
    end
  end

  let(:headers) { {} }
  let(:request_double) { instance_double(ActionDispatch::Request, headers: headers) }
  let(:routes_default_url_options) { {} }

  before do
    routes = double('routes', default_url_options: routes_default_url_options)
    application = double('application', routes: routes)
    allow(::Rails).to receive(:application).and_return(application)
  end

  describe '#html2pdf_base_tag' do
    # In real Rails, controller.url_options returns:
    #   { host: request.host, protocol: request.protocol, ... }.merge!(class_default_url_options)
    # so class default_url_options wins over request info, with request as fallback.
    context 'in a controller view' do
      let(:view) do
        view_class.new.tap do |v|
          v.request = request_double
          v.stubbed_url_options = url_options_value
        end
      end
      let(:url_options_value) { { host: 'example.com', protocol: 'https://' } }

      it 'renders a base tag with the host from url_options' do
        expect(view.html2pdf_base_tag).to eq('<base href="https://example.com">')
      end

      context 'when HTTP_X_ORIGINAL_HOST header is present (Ngrok)' do
        let(:headers) { { 'HTTP_X_ORIGINAL_HOST' => 'tunnel.ngrok.io' } }

        it 'uses the original host header' do
          expect(view.html2pdf_base_tag).to eq('<base href="https://tunnel.ngrok.io">')
        end
      end

      context 'when protocol in url_options is http' do
        let(:url_options_value) { { host: 'example.com', protocol: 'http://' } }

        it 'uses http in the base url' do
          expect(view.html2pdf_base_tag).to eq('<base href="http://example.com">')
        end
      end

      it 'allows overriding protocol via argument' do
        expect(view.html2pdf_base_tag(protocol: 'http')).to eq('<base href="http://example.com">')
      end

      it 'allows overriding host via argument' do
        expect(view.html2pdf_base_tag(host: 'arg.example')).to eq('<base href="https://arg.example">')
      end
    end

    context 'in a mailer or job view (no request)' do
      let(:view) do
        view_class.new.tap { |v| v.stubbed_url_options = url_options_value }
      end
      let(:url_options_value) { {} }

      context 'with config.action_mailer.default_url_options style url_options' do
        let(:url_options_value) { { host: 'example.com' } }

        it 'uses the host from url_options' do
          expect(view.html2pdf_base_tag).to eq('<base href="https://example.com">')
        end

        context 'when protocol is also set' do
          let(:url_options_value) { { host: 'example.com', protocol: 'http' } }

          it 'uses the protocol from url_options' do
            expect(view.html2pdf_base_tag).to eq('<base href="http://example.com">')
          end
        end
      end

      context 'with only Rails.application.routes.default_url_options set' do
        let(:routes_default_url_options) { { host: 'routes.example' } }

        it 'falls back to routes default_url_options' do
          expect(view.html2pdf_base_tag).to eq('<base href="https://routes.example">')
        end
      end

      context 'when no host is available anywhere' do
        it 'raises ArgumentError' do
          expect { view.html2pdf_base_tag }.to raise_error(ArgumentError, /host is not available/)
        end
      end
    end
  end
end
