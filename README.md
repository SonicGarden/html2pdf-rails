# html2pdf-rails

PDF generator (from HTML) gem for Ruby on Rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'html2pdf-rails'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install html2pdf-rails

## Usage

### Basic Usage

Controller

```ruby
class ThingsController < ApplicationController
  def show
    respond_to do |format|
      format.html
      format.pdf do
        render_to_pdf pdf: 'file_name'   # Excluding ".pdf" extension.
      end
    end
  end
end
```

Layout

```haml
!!!
%html
  %head
    %meta{ charset: 'utf-8' }
    = html2pdf_base_tag
    = stylesheet_link_tag 'pdf', media: 'all'
  %body
    #header= image_tag 'logo.jpg'
    #content= yield
```

### Advanced Usage with all available options

```ruby
class ThingsController < ApplicationController
  def show
    respond_to do |format|
      format.html
      format.pdf do
        render_to_pdf(
          pdf: 'file_name',                   # Excluding ".pdf" extension.
          disposition: 'attachment',          # default 'inline'
          template: 'things/show',
          layout: 'pdf',                      # for a pdf.pdf.erb file
          show_as_html: params.key?('debug'), # allow debugging based on url param
          pdf_options: {                      # SEE: https://github.com/GoogleChrome/puppeteer/blob/master/docs/api.md#pagepdfoptions
            margin: {
              top: '30px'
              bottom: '30px',
            }
          }
        )
      end
    end
  end
end
```

### Uploading pdf to S3

Add aws-sdk-s3 to your Gemfile.

```ruby
pdf_presigned_url = render_pdf_to_s3(pdf: pdf_file_name)
```

### Cloud Functions for Firebase Sample

```javascript
const functions = require("firebase-functions");
const puppeteer = require("puppeteer");
const rp = require('request-promise');

const runOptions = {
  timeoutSeconds: 20,
  memory: "1GB"
};
exports.html2pdf = functions
  .runWith(runOptions)
  .https.onRequest(
    async ({ method, body: { html = "", storageUrl = null, pdfOptions = {} } }, res) => {
      const browser = await puppeteer.launch({
        headless: true,
        args: ["--no-sandbox"]
      });
      const page = await browser.newPage();
      await page.emulateMedia("print");
      await page.goto("data:text/html;charset=UTF-8," + html, {
        waitUntil: "networkidle0"
      });
      const pdf = await page.pdf(pdfOptions);
      if (storageUrl) {
        await putToStorage(storageUrl, pdf);
        res.send("");
      } else {
        res.header({ "Content-Type": "application/pdf" });
        res.send(pdf);
      }
    }
  );
async function putToStorage(storageUrl, buffer) {
  var options = {
    method: 'PUT',
    uri: storageUrl,
    body: buffer,
    headers: {
      'content-type': 'application/pdf',
    },
    resolveWithFullResponse: true,
  };

  return rp(options);
}
```

## Configuration

In `config/initializers/html2pdf_rails.rb`, you can configure the following values.

```ruby
Html2Pdf.configure do |config|
  config.endpoint = 'YOUR_HTTP_TRIGGER_ENDPOINT'

  # for s3 upload
  config.s3 = {
    region: 'YOUR_BUCKET_REGION',
    access_key_id: 'YOUR_AWS_ACCESS_KEY_ID',
    secret_access_key: 'YOUR_AWS_SECRET_ACCESS_KEY',
    bucket: 'YOUR_BUCKET_NAME',
  }
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SonicGarden/html2pdf-rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
