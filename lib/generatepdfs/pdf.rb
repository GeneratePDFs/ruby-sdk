# frozen_string_literal: true

require 'time'
require_relative 'exceptions/invalid_argument_exception'
require_relative 'exceptions/runtime_exception'

module GeneratePDFs
  # PDF object representing a PDF document from the API
  class Pdf
    attr_reader :id, :name, :status, :download_url, :created_at

    # Create a Pdf instance from API response data.
    #
    # @param data [Hash] API response data with keys: id, name, status, download_url, created_at
    # @param client [GeneratePDFs] The GeneratePDFs client instance
    # @return [Pdf] A new Pdf instance
    # @raise [InvalidArgumentException] If data structure is invalid
    def self.from_hash(data, client)
      # Normalize keys to symbols for easier access
      normalized_data = data.transform_keys(&:to_sym)

      required_keys = %i[id name status download_url created_at]
      missing_keys = required_keys - normalized_data.keys

      unless missing_keys.empty?
        raise InvalidArgumentException, 'Invalid PDF data structure'
      end

      # Parse the created_at date
      begin
        created_at = Time.parse(normalized_data[:created_at].to_s)
      rescue ArgumentError
        raise InvalidArgumentException, "Invalid created_at format: #{normalized_data[:created_at]}"
      end

      new(
        normalized_data[:id].to_i,
        normalized_data[:name].to_s,
        normalized_data[:status].to_s,
        normalized_data[:download_url].to_s,
        created_at,
        client
      )
    end

    # Initialize a new Pdf instance
    #
    # @param id [Integer] PDF ID
    # @param name [String] PDF name
    # @param status [String] PDF status
    # @param download_url [String] Download URL
    # @param created_at [Time] Creation date
    # @param client [GeneratePDFs] The GeneratePDFs client instance
    def initialize(id, name, status, download_url, created_at, client)
      @id = id
      @name = name
      @status = status
      @download_url = download_url
      @created_at = created_at
      @client = client
    end

    # Check if the PDF is ready for download.
    #
    # @return [Boolean] True if PDF is ready
    def ready?
      @status == 'completed'
    end

    # Download the PDF content.
    #
    # @return [String] PDF binary content
    # @raise [RuntimeException] If the PDF is not ready or download fails
    def download
      unless ready?
        raise RuntimeException, "PDF is not ready yet. Current status: #{@status}"
      end

      @client.download_pdf(@download_url)
    end

    # Download the PDF and save it to a file.
    #
    # @param file_path [String] Path where to save the PDF file
    # @return [Boolean] True on success
    # @raise [RuntimeException] If the PDF is not ready or download fails
    def download_to_file(file_path)
      content = download

      File.binwrite(file_path, content)
      true
    rescue StandardError => e
      raise RuntimeException, "Failed to write PDF to file: #{file_path} - #{e.message}"
    end

    # Refresh the PDF data from the API.
    #
    # @return [Pdf] A new Pdf instance with updated data
    def refresh
      @client.get_pdf(@id)
    end
  end
end
