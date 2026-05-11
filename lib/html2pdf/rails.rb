require 'retryable'
require 'html2pdf/rails/version'
require 'html2pdf/rails/errors'
require 'html2pdf/rails/client'
require 'html2pdf/rails/railtie'

module Html2Pdf
  class Config
    attr_accessor :endpoint, :app

    def initialize
      @endpoint = nil
      @app = nil
    end
  end

  class << self
    def configure(&block)
      yield config
    end

    def config
      @config ||= Config.new
    end
  end

  module Rails
    def self.generate(html:, pdf_options: {})
      Retryable.retryable(tries: 3, on: ServiceUnavailableError) do
        Client.post(html: html, pdf_options: pdf_options)
      end
    end
  end
end
