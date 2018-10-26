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
    = pdf_base_tag
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

### Cloud Functions for Firebase Sample

```javascript
const functions = require('firebase-functions');
const puppeteer = require('puppeteer');

const runOptions = {
  timeoutSeconds: 20,
  memory: '1GB',
};
exports.html2pdf = functions
  .runWith(runOptions)
  .https.onRequest(async ({ method, body: { html = '', pdfOptions = {} } }, res) => {
    const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
    const page = await browser.newPage();
    await page.emulateMedia('print');
    await page.goto("data:text/html;charset=UTF-8," + html, {
      waitUntil: "networkidle0"
    });
    const pdf = await page.pdf(pdfOptions)
    res.header({ 'Content-Type': 'application/pdf' });
    res.send(pdf);
  });
```

## Configuration

In `config/initializers/html2pdf_rails.rb`, you can configure the following values.

```ruby
Rails.application.configure do
  config.html2pdf_rails.endpoint = 'YOUR_HTTP_TRIGGER_ENDPOINT'
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SonicGarden/html2pdf-rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
