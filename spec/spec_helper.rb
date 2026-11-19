require 'bundler/setup'
require 'html2pdf/rails'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  # Start every example without an API key, even when HTML2PDF_API_KEY is exported in the shell running rspec.
  # Resetting before each example (rather than restoring afterwards) also keeps a key set by one example
  # from reaching the next, in any spec file and in random order.
  config.before do
    ENV.delete('HTML2PDF_API_KEY')
    Html2Pdf.config.api_key = nil
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
