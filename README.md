# GeneratePDFs Ruby SDK

Ruby SDK for the [GeneratePDFs.com](https://generatepdfs.com) API, your go-to place for HTML to PDF.

Upload your HTML files, along with any CSS files and images to generate a PDF. Alternatively provide a URL to generate a PDF from it's contents.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'generatepdfs'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install generatepdfs
```

## Get your API Token

Sign up for an account on [GeneratePDFs.com](https://generatepdfs.com) and head to the API Tokens section and create a new token.

## Usage

### Basic Setup

```ruby
require 'generatepdfs'

client = GeneratePDFs::GeneratePDFs.connect('YOUR_API_TOKEN')
```

### Generate PDF from HTML File

```ruby
require 'generatepdfs'

# Simple HTML file
pdf = client.generate_from_html('/path/to/file.html')

# HTML file with CSS
pdf = client.generate_from_html(
  '/path/to/file.html',
  '/path/to/file.css'
)

# HTML file with CSS and images
pdf = client.generate_from_html(
  '/path/to/file.html',
  '/path/to/file.css',
  [
    {
      name: 'logo.png',
      path: '/path/to/logo.png',
      mime_type: 'image/png' # Optional, will be auto-detected
    },
    {
      name: 'photo.jpg',
      path: '/path/to/photo.jpg'
    }
  ]
)
```

### Generate PDF from URL

```ruby
pdf = client.generate_from_url('https://example.com')
```

### Get PDF by ID

```ruby
# Retrieve a PDF by its ID
pdf = client.get_pdf(123)
```

### Working with PDF Objects

The SDK returns `Pdf` objects that provide easy access to PDF information and downloading:

```ruby
# Access PDF properties
pdf_id = pdf.id
pdf_name = pdf.name
status = pdf.status
download_url = pdf.download_url
created_at = pdf.created_at

# Check if PDF is ready
if pdf.ready?
  # Download PDF content as string
  pdf_content = pdf.download
  
  # Or save directly to file
  pdf.download_to_file('/path/to/save/output.pdf')
end

# Refresh PDF data from the API (useful for checking status updates)
refreshed_pdf = pdf.refresh
if refreshed_pdf.ready?
  pdf_content = refreshed_pdf.download
end
```

### Client Methods

- `generate_from_html(html_path, css_path = nil, images = [])` - Generate a PDF from HTML file(s)
- `generate_from_url(url)` - Generate a PDF from a URL
- `get_pdf(id)` - Retrieve a PDF by its ID
- `download_pdf(download_url)` - Download PDF binary content from a download URL

### PDF Object Methods

- `id` - Get the PDF ID
- `name` - Get the PDF filename
- `status` - Get the current status (pending, processing, completed, failed)
- `download_url` - Get the download URL
- `created_at` - Get the creation date
- `ready?` - Check if the PDF is ready for download
- `download` - Download and return PDF binary content
- `download_to_file(file_path)` - Download and save PDF to a file
- `refresh` - Refresh PDF data from the API and return a new Pdf instance with updated information

## Requirements

- Ruby 3.0 or higher
- Faraday 2.0 or higher
- MIME::Types 3.0 or higher

## Testing

To run the test suite, execute:

```bash
bundle exec rspec
```

To run tests with coverage:

```bash
bundle exec rspec --format documentation
```

## Contributing

Contributions and suggestions are **welcome** and will be fully **credited**.

We accept contributions via Pull Requests on [GitHub](https://github.com/GeneratePDFs/ruby-sdk).

### Pull Requests

- **Follow Ruby style guide** - Use RuboCop to ensure code style consistency
- **Add tests!** - Your patch won't be accepted if it doesn't have tests.
- **Document any change in behaviour** - Make sure the README / CHANGELOG and any other relevant documentation are kept up-to-date.
- **Consider our release cycle** - We try to follow semver. Randomly breaking public APIs is not an option.
- **Create topic branches** - Don't ask us to pull from your master branch.
- **One pull request per feature** - If you want to do more than one thing, send multiple pull requests.
- **Send coherent history** - Make sure each individual commit in your pull request is meaningful. If you had to make multiple intermediate commits while developing, please squash them before submitting.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a history of changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
