# frozen_string_literal: true

module Html2Pdf
  module Rails
    class S3
      class << self
        def presigned_put_url(key)
          instance.presigned_url(:put_object, key)
        end

        def presigned_get_url(key, disposition: nil)
          options = {}
          options[:response_content_disposition] ||= 'inline'
          instance.presigned_url(:get_object, key, **options)
        end

        def instance
          self.new(**s3_options)
        end

        def s3_options
          if Html2Pdf.config.s3.is_a?(Hash)
            Html2Pdf.config.s3.slice(:region, :access_key_id, :secret_access_key, :bucket)
          end
        end
      end

      def initialize(region:, access_key_id:, secret_access_key:, bucket:)
        unless defined?(Aws::S3::Client)
          raise 'Add aws-sdk-s3 to Gemfile if s3 upload feature is required.'
        end
        @client = Aws::S3::Client.new(
          region: region,
          access_key_id: access_key_id,
          secret_access_key: secret_access_key
        )
        @signer = Aws::S3::Presigner.new(client: @client)
        @bucket = bucket
      end

      def presigned_url(method, key, **options)
        @signer.presigned_url(method, options.merge(bucket: @bucket, key: key))
      end
    end
  end
end
