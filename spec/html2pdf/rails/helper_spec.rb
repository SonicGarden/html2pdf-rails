# frozen_string_literal: true

require 'spec_helper'
require 'action_view'

RSpec.describe Html2Pdf::Rails::Helper do
  let(:view_class) do
    Class.new do
      include ActionView::Helpers::TagHelper
      include Html2Pdf::Rails::Helper

      attr_accessor :request

      def output_buffer
        @output_buffer ||= ActionView::OutputBuffer.new
      end
    end
  end

  let(:view_class_without_request) do
    Class.new do
      include ActionView::Helpers::TagHelper
      include Html2Pdf::Rails::Helper

      def output_buffer
        @output_buffer ||= ActionView::OutputBuffer.new
      end
    end
  end

  let(:headers) { {} }
  let(:request) do
    instance_double(
      ActionDispatch::Request,
      headers: headers,
      host: 'example.com',
      scheme: 'https'
    )
  end

  before do
    Html2Pdf.config.default_host = nil
    Html2Pdf.config.default_protocol = nil
  end

  describe '#html2pdf_base_tag' do
    context 'when request is available (controller context)' do
      let(:view) { view_class.new.tap { |v| v.request = request } }

      it 'renders a base tag with the request host' do
        expect(view.html2pdf_base_tag).to eq('<base href="https://example.com">')
      end

      context 'when HTTP_X_ORIGINAL_HOST header is present' do
        let(:headers) { { 'HTTP_X_ORIGINAL_HOST' => 'tunnel.ngrok.io' } }

        it 'uses the original host instead of request.host' do
          expect(view.html2pdf_base_tag).to eq('<base href="https://tunnel.ngrok.io">')
        end
      end

      context 'when scheme is http' do
        let(:request) do
          instance_double(
            ActionDispatch::Request,
            headers: headers,
            host: 'example.com',
            scheme: 'http'
          )
        end

        it 'uses http in the base url' do
          expect(view.html2pdf_base_tag).to eq('<base href="http://example.com">')
        end
      end

      it 'allows overriding protocol via argument' do
        expect(view.html2pdf_base_tag(protocol: 'http')).to eq('<base href="http://example.com">')
      end
    end

    context 'when request is not available (mailer/job context)' do
      let(:view) { view_class_without_request.new }

      context 'with config defaults set' do
        before do
          Html2Pdf.config.default_host = 'example.com'
        end

        it 'uses the configured default host' do
          expect(view.html2pdf_base_tag).to eq('<base href="https://example.com">')
        end

        it 'uses configured default_protocol when set' do
          Html2Pdf.config.default_protocol = 'http'
          expect(view.html2pdf_base_tag).to eq('<base href="http://example.com">')
        end
      end

      context 'when no host is available' do
        it 'raises ArgumentError' do
          expect { view.html2pdf_base_tag }.to raise_error(ArgumentError, /host is not available/)
        end
      end
    end

    context 'argument precedence' do
      let(:view) { view_class.new.tap { |v| v.request = request } }

      before do
        Html2Pdf.config.default_host = 'config.example'
      end

      it 'prefers explicit argument over request and config' do
        expect(view.html2pdf_base_tag(host: 'arg.example')).to eq('<base href="https://arg.example">')
      end

      it 'prefers request over config when argument is not given' do
        expect(view.html2pdf_base_tag).to eq('<base href="https://example.com">')
      end
    end
  end
end
