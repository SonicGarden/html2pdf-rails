# frozen_string_literal: true

require 'html2pdf/rails/errors'

module Html2Pdf
  module Rails
    module ApiKey
      # Returns the key with surrounding whitespace removed, or nil when it is blank
      # (nil, '' or only whitespace), so that callers can treat blank as "not set".
      def self.normalize(value)
        key = value.to_s.strip
        return nil if key.empty?
        # NOTE: Never include the key in the message. Net::HTTP would otherwise raise its own
        # ArgumentError for a CR/LF inside the header value, and that message contains the value.
        raise InvalidApiKeyError, 'html2pdf api_key must not contain whitespace' if key.match?(/\s/)

        key
      end
    end
  end
end
