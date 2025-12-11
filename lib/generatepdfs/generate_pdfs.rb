# frozen_string_literal: true

require 'faraday'
require 'base64'
require 'json'
require 'uri'
require 'mime/types'
require_relative 'pdf'
require_relative 'exceptions/invalid_argument_exception'
require_relative 'exceptions/runtime_exception'

module GeneratePDFs
  # Main client class for interacting with the GeneratePDFs API
  class GeneratePDFs
    BASE_URL = 'https://api.generatepdfs.com'

    # Create a new GeneratePDFs instance with the provided API token.
    #
    # @param api_token [String] The API token for authentication
    # @return [GeneratePDFs] A new GeneratePDFs instance
    def self.connect(api_token)
      new(api_token)
    end

    # Initialize a new GeneratePDFs client
    #
    # @param api_token [String] The API token for authentication
    def initialize(api_token)
      @api_token = api_token
      @client = Faraday.new(
        url: BASE_URL,
        headers: {
          'Content-Type' => 'application/json'
        }
      ) do |conn|
        conn.request :json
        conn.response :json
        conn.adapter Faraday.default_adapter
      end
    end

    # Generate a PDF from HTML file(s) with optional CSS and images.
    #
    # @param html_path [String] Path to the HTML file
    # @param css_path [String, nil] Optional path to the CSS file
    # @param images [Array<Hash>] Optional array of image files with keys: :name, :path, :mime_type
    # @return [Pdf] PDF object containing PDF information
    # @raise [InvalidArgumentException] If files are invalid
    def generate_from_html(html_path, css_path = nil, images = [])
      unless File.exist?(html_path) && File.readable?(html_path)
        raise InvalidArgumentException, "HTML file not found or not readable: #{html_path}"
      end

      html_content = Base64.strict_encode64(File.read(html_path))

      data = {
        html: html_content
      }

      if css_path
        unless File.exist?(css_path) && File.readable?(css_path)
          raise InvalidArgumentException, "CSS file not found or not readable: #{css_path}"
        end

        data[:css] = Base64.strict_encode64(File.read(css_path))
      end

      data[:images] = process_images(images) unless images.empty?

      response = make_request('/pdfs/generate', data)

      data_hash = response['data'] || response[:data]
      unless data_hash
        raise InvalidArgumentException, 'Invalid API response: missing data'
      end

      Pdf.from_hash(data_hash, self)
    end

    # Generate a PDF from a URL.
    #
    # @param url [String] The URL to convert to PDF
    # @return [Pdf] PDF object containing PDF information
    # @raise [InvalidArgumentException] If URL is invalid
    def generate_from_url(url)
      begin
        uri = URI.parse(url)
        raise InvalidArgumentException, "Invalid URL: #{url}" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
        raise InvalidArgumentException, "Invalid URL: #{url}"
      end

      data = {
        url: url
      }

      response = make_request('/pdfs/generate', data)

      data_hash = response['data'] || response[:data]
      unless data_hash
        raise InvalidArgumentException, 'Invalid API response: missing data'
      end

      Pdf.from_hash(data_hash, self)
    end

    # Get a PDF by its ID.
    #
    # @param id [Integer] The PDF ID
    # @return [Pdf] PDF object containing PDF information
    # @raise [InvalidArgumentException] If ID is invalid
    def get_pdf(id)
      if id <= 0
        raise InvalidArgumentException, "Invalid PDF ID: #{id}"
      end

      response = make_get_request("/pdfs/#{id}")

      data_hash = response['data'] || response[:data]
      unless data_hash
        raise InvalidArgumentException, 'Invalid API response: missing data'
      end

      Pdf.from_hash(data_hash, self)
    end

    # Download a PDF from the API.
    #
    # @param download_url [String] The download URL for the PDF
    # @return [String] PDF binary content
    def download_pdf(download_url)
      response = @client.get(download_url) do |req|
        req.headers['Authorization'] = "Bearer #{@api_token}"
      end

      raise RuntimeException, "Failed to download PDF: #{response.status}" unless response.success?

      response.body
    end

    private

    # Process image files and return formatted array for API.
    #
    # @param images [Array<Hash>] Array of image inputs with keys: :name, :path, :mime_type
    # @return [Array<Hash>] Array of processed images
    def process_images(images)
      processed = []

      images.each do |image|
        next unless image[:path] && image[:name]

        path = image[:path]
        name = image[:name]

        next unless File.exist?(path) && File.readable?(path)

        content = Base64.strict_encode64(File.read(path))

        # Detect mime type if not provided
        mime_type = image[:mime_type] || detect_mime_type(path)

        processed << {
          name: name,
          content: content,
          mime_type: mime_type
        }
      end

      processed
    end

    # Detect MIME type of a file.
    #
    # @param file_path [String] Path to the file
    # @return [String] MIME type
    def detect_mime_type(file_path)
      mime_type = MIME::Types.type_for(file_path).first
      return mime_type.to_s if mime_type

      # Fallback to extension-based detection
      extension = File.extname(file_path).downcase.delete_prefix('.')
      mime_types = {
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'svg' => 'image/svg+xml'
      }

      mime_types[extension] || 'application/octet-stream'
    end

    # Make an HTTP POST request to the API.
    #
    # @param endpoint [String] API endpoint
    # @param data [Hash] Request data
    # @return [Hash] Decoded JSON response
    def make_request(endpoint, data)
      response = @client.post(endpoint) do |req|
        req.headers['Authorization'] = "Bearer #{@api_token}"
        req.body = data.to_json
      end

      unless response.success?
        error_msg = response.reason_phrase || response.status.to_s
        raise RuntimeException, "API request failed: #{response.status} #{error_msg}"
      end

      response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
    end

    # Make an HTTP GET request to the API.
    #
    # @param endpoint [String] API endpoint
    # @return [Hash] Decoded JSON response
    def make_get_request(endpoint)
      response = @client.get(endpoint) do |req|
        req.headers['Authorization'] = "Bearer #{@api_token}"
      end

      unless response.success?
        error_msg = response.reason_phrase || response.status.to_s
        raise RuntimeException, "API request failed: #{response.status} #{error_msg}"
      end

      response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
    end
  end
end
