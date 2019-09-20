require 'active_support/configurable'
require 'html2pdf/rails/version'
require 'html2pdf/rails/railtie'

module Html2Pdf
  class Config
    include ActiveSupport::Configurable
    config_accessor :endpoint
    config_accessor :s3
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
