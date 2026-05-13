![CI](https://github.com/SonicGarden/html2pdf-rails/actions/workflows/ci.yml/badge.svg)

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

### Put PDF to Cloud Storage and return signed url
You can get signed url of Cloud Storage if your Cloud Funciton code support it.

```ruby
  pdf_url = render_pdf_and_get_url pdf: 'file_name'
  redirect_to pdf_url
```

### Attach PDF to an email (ActionMailer)

`render_to_pdf_string` is available in all mailers. It renders a template, converts it to PDF, and returns the PDF binary.

```ruby
class OrderMailer < ApplicationMailer
  def receipt(order)
    @order = order
    attachments['receipt.pdf'] = render_to_pdf_string
    mail(to: order.user.email)
  end
end
```

By default, the template is inferred from `<mailer_name>/<action_name>` and `formats: [:pdf]` is used. So the example above renders `order_mailer/receipt.pdf.erb`. You can override these defaults:

```ruby
attachments['receipt.pdf'] = render_to_pdf_string(
  template: 'order_mailer/receipt_pdf',
  layout: 'pdf',
  pdf_options: { margin: { top: '30px' } }
)
```

### Generate PDF from arbitrary HTML

If you already have an HTML string (for example, in a background job or PORO), use the low-level API:

```ruby
html = ApplicationController.render(template: 'invoices/show', assigns: { invoice: invoice })
pdf = Html2Pdf::Rails.generate(html: html, pdf_options: { margin: { top: '30px' } })
File.binwrite('invoice.pdf', pdf)
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
          pdf_options: {                      # SEE: https://pptr.dev/api/puppeteer.pdfoptions
            margin: {
              top: '30px',
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
const functions = require("firebase-functions");
const puppeteer = require("puppeteer");

const runOptions = {
  timeoutSeconds: 20,
  memory: "1GB"
};
exports.html2pdf = functions
  .runWith(runOptions)
  .https.onRequest(
    async ({ method, body: { html = "", putToStorage = false, pdfOptions = {} } }, res) => {
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
      if (putToStorage) {
        // Code for Cloud Storage is omitted.
      } else {
        res.header({ "Content-Type": "application/pdf" });
        res.send(pdf);
      }
    }
  );
```

## Configuration

In `config/initializers/html2pdf_rails.rb`, you can configure the following values.

```ruby
Html2Pdf.configure do |config|
  config.endpoint = 'YOUR_HTTP_TRIGGER_ENDPOINT'
end
```

### `html2pdf_base_tag` in mailers / jobs

`html2pdf_base_tag` resolves the base URL in this order (matches Rails `url_for`):

1. Explicit `host:` / `protocol:` argument
2. `HTTP_X_ORIGINAL_HOST` request header (host only, for Ngrok-style proxying)
3. View-context `url_options[:host]` / `[:protocol]`:
   - In a controller view: `config.action_controller.default_url_options` merged over `request.host` / `request.protocol` (config wins, request as fallback — same behavior as Rails `url_for`)
   - In a mailer view: `config.action_mailer.default_url_options`
4. `Rails.application.routes.default_url_options[:host]` / `[:protocol]` (final fallback)

Most Rails apps already configure `config.action_mailer.default_url_options` for mailer URL helpers, so no extra setup is usually required:

```ruby
# config/environments/production.rb
config.action_mailer.default_url_options = { host: 'example.com', protocol: 'https' }
```

If you want to override per-call (e.g. multi-tenant), pass arguments:

```erb
<%= html2pdf_base_tag host: 'tenant.example.com', protocol: 'https' %>
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SonicGarden/html2pdf-rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
