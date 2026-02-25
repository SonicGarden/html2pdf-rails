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
