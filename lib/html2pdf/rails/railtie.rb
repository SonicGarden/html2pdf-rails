# frozen_string_literal: true

require 'html2pdf/rails/rendering'
require 'html2pdf/rails/helper'

module Html2Pdf
  module Rails
    class Railtie < ::Rails::Railtie
      ActiveSupport.on_load(:action_controller) do
        ActionController::Base.prepend Rendering
      end

      ActiveSupport.on_load(:action_view) do
        ActionView::Base.include Helper
      end

      config.after_initialize do |app|
        if Html2Pdf.config.endpoint.blank?
          raise 'Html2Pdf.config.endpoint is required'
        end
        Html2Pdf.config.app ||= app.class.module_parent_name
      end
    end
  end
end
