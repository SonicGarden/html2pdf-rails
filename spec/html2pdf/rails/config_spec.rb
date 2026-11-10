# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Html2Pdf::Config do
  before do
    Html2Pdf.instance_variable_set(:@config, nil)
  end

  describe '.config' do
    it 'returns a Config instance' do
      expect(Html2Pdf.config).to be_a(Html2Pdf::Config)
    end

    it 'returns the same instance on multiple calls' do
      config1 = Html2Pdf.config
      config2 = Html2Pdf.config
      expect(config1).to eq(config2)
    end

    it 'initializes with nil values' do
      expect(Html2Pdf.config.endpoint).to be_nil
      expect(Html2Pdf.config.app).to be_nil
    end

    it 'reads api_key from ENV["HTML2PDF_API_KEY"] when not configured' do
      ENV['HTML2PDF_API_KEY'] = 'sgh2p_from_env'
      expect(Html2Pdf.config.api_key).to eq('sgh2p_from_env')

      Html2Pdf.config.api_key = 'sgh2p_configured'
      expect(Html2Pdf.config.api_key).to eq('sgh2p_configured')
    end

    describe 'api_key normalization' do
      it 'falls back to ENV when the configured key is blank' do
        ENV['HTML2PDF_API_KEY'] = 'sgh2p_from_env'
        ['', '  ', nil].each do |blank|
          Html2Pdf.config.api_key = blank
          expect(Html2Pdf.config.api_key).to eq('sgh2p_from_env')
        end
      end

      it 'is nil when both the configured key and ENV are blank' do
        ENV['HTML2PDF_API_KEY'] = " \n"
        Html2Pdf.config.api_key = ''
        expect(Html2Pdf.config.api_key).to be_nil
      end

      it 'removes surrounding whitespace such as a trailing newline' do
        Html2Pdf.config.api_key = " sgh2p_configured\n"
        expect(Html2Pdf.config.api_key).to eq('sgh2p_configured')
      end

      it 'converts a non-string value to a string' do
        Html2Pdf.config.api_key = 12345
        expect(Html2Pdf.config.api_key).to eq('12345')
      end

      it 'raises InvalidApiKeyError without the key in the message when the key contains whitespace' do
        Html2Pdf.config.api_key = "sgh2p_secret\nvalue"
        expect { Html2Pdf.config.api_key }.to raise_error(Html2Pdf::Rails::InvalidApiKeyError) { |e|
          expect(e.message).not_to include('sgh2p_secret')
        }
      end
    end
  end

  describe '.configure' do
    it 'allows setting endpoint via block' do
      Html2Pdf.configure do |config|
        config.endpoint = 'https://example.com/api'
      end
      expect(Html2Pdf.config.endpoint).to eq('https://example.com/api')
    end

    it 'allows setting app via block' do
      Html2Pdf.configure do |config|
        config.app = 'MyApp'
      end
      expect(Html2Pdf.config.app).to eq('MyApp')
    end

    it 'allows setting multiple values in one block' do
      Html2Pdf.configure do |config|
        config.endpoint = 'https://example.com/api'
        config.app = 'MyApp'
      end
      expect(Html2Pdf.config.endpoint).to eq('https://example.com/api')
      expect(Html2Pdf.config.app).to eq('MyApp')
    end

    it 'persists configuration across multiple configure calls' do
      Html2Pdf.configure { |c| c.endpoint = 'https://example.com' }
      Html2Pdf.configure { |c| c.app = 'MyApp' }

      expect(Html2Pdf.config.endpoint).to eq('https://example.com')
      expect(Html2Pdf.config.app).to eq('MyApp')
    end
  end

  describe 'direct attribute access' do
    it 'allows reading endpoint directly' do
      Html2Pdf.config.endpoint = 'https://direct.com'
      expect(Html2Pdf.config.endpoint).to eq('https://direct.com')
    end

    it 'allows reading app directly' do
      Html2Pdf.config.app = 'DirectApp'
      expect(Html2Pdf.config.app).to eq('DirectApp')
    end

    it 'allows ||= assignment pattern' do
      Html2Pdf.config.app = nil
      Html2Pdf.config.app ||= 'DefaultApp'
      expect(Html2Pdf.config.app).to eq('DefaultApp')

      Html2Pdf.config.app ||= 'ShouldNotOverwrite'
      expect(Html2Pdf.config.app).to eq('DefaultApp')
    end
  end

  describe 'backwards compatibility' do
    it 'supports the typical initializer pattern' do
      Html2Pdf.configure do |config|
        config.endpoint = 'YOUR_HTTP_TRIGGER_ENDPOINT'
      end

      expect(Html2Pdf.config.endpoint).to eq('YOUR_HTTP_TRIGGER_ENDPOINT')
    end
  end
end
