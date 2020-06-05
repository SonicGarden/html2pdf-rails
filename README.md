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

### Cloud Functions for Firebase Sample

```javascript
const functions = require("firebase-functions");
const admin = require('firebase-admin');
const puppeteer = require("puppeteer");
const uuidv4 = require('uuid/v4');
const {promisify} = require('util');

const runOptions = {
  timeoutSeconds: 60,
  memory: "2GB"
};

admin.initializeApp();
const storage = admin.storage();

exports.pdf = functions
  .region("asia-northeast1")
  .runWith(runOptions)
  .https.onRequest(
    async ({method, body}, res) => {
      try {
        await handleHttp({method, body}, res);
      } catch (err) {
        // https://cloud.google.com/functions/docs/monitoring/error-reporting
        if (err instanceof Error) {
          console.error(err);
        } else {
          console.error(new Error(err));
        }
        res.status(500).end();
      }
    }
  );

async function handleHttp({ method, body: { html = "", putToStorage = false, fileName = 'tmp', responseDisposition = null, pdfOptions = {} } }, res) {
  setCors(res);
  if (["OPTIONS"].includes(method)) return res.send("");
  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '-–disable-dev-shm-usage',
      '--disable-gpu',
      '--no-first-run',
      '--no-zygote',
      '--single-process',
    ]
  });
  const page = await browser.newPage();

  // NOTE: suppress console warnings
  page.on("console", consoleObj => console.log(consoleObj.text()));

  await page.emulateMedia("print");
  await page.setContent(html, {
    waitUntil: ["load", "networkidle0"]
  });
  const pdf = await page.pdf(pdfOptions);
  if (putToStorage) {
    await putToCloudStorage(res, pdf, fileName, responseDisposition);
  } else {
    res.header({ "Content-Type": "application/pdf" });
    res.send(pdf);
  }
  await browser.close();
}

function setCors(res) {
  res.header({
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "*"
  });
}

async function putToCloudStorage(res, buffer, fileName, responseDisposition) {
  const newFile = await makeCloudStorageFile(buffer, fileName);
  const [url] = await getSignedUrl(newFile, fileName, responseDisposition);
  const json = JSON.stringify({url: url});
  res.header({ "Content-Type": "application/json" });
  res.send(json);
}

async function makeCloudStorageFile(buffer, fileName) {
  const path = `${uuidv4()}/${fileName}`;
  const newFile = storage.bucket().file(path);
  const blobStream = newFile.createWriteStream({
    metadata:{
        contentType: 'application/pdf',
    }
  });
  const end = promisify(blobStream.end).bind(blobStream);
  await end(buffer);
  return newFile;
}

function getSignedUrl(file, fileName, responseDisposition) {
  if (responseDisposition === null) {
    responseDisposition = 'inline';
  }
  if (!/filename/.test(responseDisposition)) {
    responseDisposition += `; filename*=UTF-8''${encodeURIComponent(fileName)}`;
  }
  const expiresAtMs = Date.now() + 300000;
  const config = {
      action: 'read',
      expires: expiresAtMs,
  };
  if (responseDisposition) {
    config.responseDisposition = responseDisposition;
  }
  return file.getSignedUrl(config);
}
```

## Configuration

In `config/initializers/html2pdf_rails.rb`, you can configure the following values.

```ruby
Html2Pdf.configure do |config|
  config.endpoint = 'YOUR_HTTP_TRIGGER_ENDPOINT'
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SonicGarden/html2pdf-rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
