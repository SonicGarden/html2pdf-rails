# frozen_string_literal: true

require "html2pdf/rails/rendering"
require "html2pdf/rails/helper"

module Html2Pdf
  module Rails
    class Railtie < ::Rails::Railtie
      config.html2pdf_rails = ActiveSupport::OrderedOptions.new
      config.html2pdf_rails.endpoint = nil

      initializer 'html2pdf-rails.register' do |_app|
        ActionController::Base.send :prepend, Rendering
        ActionView::Base.send :include, Helper
      end

      config.after_initialize do
        if config.html2pdf_rails.endpoint.blank?
          raise 'config.html2pdf_rails.endpoint is required'
        end
      end
    end
  end
end
