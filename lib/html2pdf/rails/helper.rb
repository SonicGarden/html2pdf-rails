# frozen_string_literal: true

module Html2Pdf
  module Rails
    module Helper
      # Resolves the base URL in the same order as Rails' `url_for`, with one
      # gem-specific addition (HTTP_X_ORIGINAL_HOST). See `_html2pdf_default_url_options`
      # for the source of `options`.
      def html2pdf_base_tag(host: nil, protocol: nil)
        req = _html2pdf_request
        options = _html2pdf_default_url_options

        # HTTP_X_ORIGINAL_HOST overrides options because dev tunneling (Ngrok) sets
        # this header to the externally-visible host that puppeteer must reach,
        # which doesn't match request.host or any configured default.
        host ||= req && req.headers['HTTP_X_ORIGINAL_HOST']
        host ||= options[:host]
        if host.blank?
          raise ArgumentError,
                'html2pdf_base_tag: host is not available. Pass `host:` or configure default_url_options (e.g. config.action_mailer.default_url_options).'
        end

        # options[:protocol] from controller's url_options is "https://" (with trailing
        # "://" — request.protocol convention), while config and mailer values are
        # bare "https". Normalize.
        protocol ||= options[:protocol]&.to_s&.delete_suffix('://')
        protocol ||= 'https'

        tag.base href: "#{protocol}://#{host}"
      end

      private

      def _html2pdf_request
        respond_to?(:request) ? request : nil
      end

      # Mirrors how Rails' `url_for` resolves URL options, so this helper produces
      # the same host/protocol as `url_for` would in the same context.
      #
      # `view.url_options` delegates to `controller.url_options`:
      # https://github.com/rails/rails/blob/v8.1.2/actionview/lib/action_view/routing_url_for.rb#L124
      #
      # In a controller this returns
      # `{ host: request.host, protocol: request.protocol, ... }.merge!(super)`:
      # https://github.com/rails/rails/blob/v8.1.2/actionpack/lib/action_controller/metal/url_for.rb#L37
      # `merge!` lets class-level `default_url_options` win over request info.
      # In a mailer it returns the class-level `default_url_options` directly
      # (no request to merge in).
      #
      # `RouteSet#url_for` then does `default_url_options.merge(options)`, so
      # routes' default is the base under everything else. We replicate that here:
      # https://github.com/rails/rails/blob/v8.1.2/actionpack/lib/action_dispatch/routing/route_set.rb#L856
      #
      # Note: `config.action_mailer.default_url_options` and
      # `config.action_controller.default_url_options` populate the *class*
      # `default_url_options`, NOT `Rails.application.routes.default_url_options` —
      # they are three separate hashes. Reading only the routes hash would miss the
      # typical mailer setup.
      def _html2pdf_default_url_options
        routes_options = ::Rails.application&.routes&.default_url_options || {}
        context_options = respond_to?(:url_options) ? url_options : {}
        routes_options.merge(context_options)
      end
    end
  end
end
