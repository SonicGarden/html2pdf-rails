require 'retryable'
require 'html2pdf/rails/version'
require 'html2pdf/rails/errors'
require 'html2pdf/rails/api_key'
require 'html2pdf/rails/client'
require 'html2pdf/rails/railtie'

module Html2Pdf
  class Config
    attr_accessor :endpoint, :app
    attr_writer :api_key

    def initialize
      @endpoint = nil
      @app = nil
      @api_key = nil
    end

    # Falls back to ENV at read time (not in #initialize) so that the key can be
    # set after the config object is built, e.g. by dotenv loading later in boot.
    # A blank value also falls back, because `credentials.xxx.to_s` and the like
    # yield '' when the key is not set.
    def api_key
      Html2Pdf::Rails::ApiKey.normalize(@api_key) || Html2Pdf::Rails::ApiKey.normalize(ENV['HTML2PDF_API_KEY'])
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
