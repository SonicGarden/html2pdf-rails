require 'retryable'
require 'html2pdf/rails/version'
require 'html2pdf/rails/errors'
require 'html2pdf/rails/client'
require 'html2pdf/rails/railtie'

module Html2Pdf
  class Config
    attr_accessor :endpoint, :app, :default_host, :default_protocol

    def initialize
      @endpoint = nil
      @app = nil
      @default_host = nil
      @default_protocol = nil
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
    def self.generate(html:, pdf_options: {}, put_to_storage: false, file_name: nil, disposition: nil)
      Retryable.retryable(tries: 3, on: ServiceUnavailableError) do
        Client.post(
          html: html,
          pdf_options: pdf_options,
          put_to_storage: put_to_storage,
          file_name: file_name,
          disposition: disposition
        )
      end
    end
  end
end
