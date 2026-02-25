require 'html2pdf/rails/version'
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
end
