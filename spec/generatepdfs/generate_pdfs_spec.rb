# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GeneratePDFs::GeneratePDFs do
  let(:api_token) { 'test-api-token' }
  let(:base_url) { 'https://api.generatepdfs.com' }
  let(:client) { described_class.connect(api_token) }

  describe '.connect' do
    it 'creates a new GeneratePDFs instance' do
      expect(client).to be_instance_of(described_class)
    end
  end

  describe '#generate_from_html' do
    context 'when HTML file does not exist' do
      it 'raises InvalidArgumentException' do
        expect do
          client.generate_from_html('/non/existent/file.html')
        end.to raise_error(GeneratePDFs::InvalidArgumentException, 'HTML file not found or not readable: /non/existent/file.html')
      end
    end

    context 'when HTML file is not readable' do
      let(:temp_file) { Tempfile.new(['test', '.html']) }

      before do
        temp_file.close
        File.chmod(0o000, temp_file.path)
      end

      after do
        File.chmod(0o644, temp_file.path) if File.exist?(temp_file.path)
        temp_file.unlink
      end

      it 'raises InvalidArgumentException' do
        expect do
          client.generate_from_html(temp_file.path)
        end.to raise_error(GeneratePDFs::InvalidArgumentException, /HTML file not found or not readable/)
      end
    end

    context 'when CSS file does not exist' do
      let(:html_file) { Tempfile.new(['test', '.html']) }

      before do
        html_file.write('<html><body>Test</body></html>')
        html_file.close
      end

      after { html_file.unlink }

      it 'raises InvalidArgumentException' do
        expect do
          client.generate_from_html(html_file.path, '/non/existent/file.css')
        end.to raise_error(GeneratePDFs::InvalidArgumentException, 'CSS file not found or not readable: /non/existent/file.css')
      end
    end

    context 'when successfully generating PDF from HTML file' do
      let(:html_file) { Tempfile.new(['test', '.html']) }
      let(:mock_response) do
        {
          'data' => {
            'id' => 123,
            'name' => 'test.pdf',
            'status' => 'pending',
            'download_url' => 'https://api.generatepdfs.com/pdfs/123/download/token',
            'created_at' => '2024-01-01T12:00:00.000000Z'
          }
        }
      end

      before do
        html_file.write('<html><body>Test</body></html>')
        html_file.close

        stub_request(:post, "#{base_url}/pdfs/generate")
          .with(
            headers: {
              'Authorization' => "Bearer #{api_token}",
              'Content-Type' => 'application/json'
            },
            body: hash_including('html')
          )
          .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      after { html_file.unlink }

      it 'returns a Pdf instance' do
        pdf = client.generate_from_html(html_file.path)

        expect(pdf).to be_instance_of(GeneratePDFs::Pdf)
        expect(pdf.id).to eq(123)
        expect(pdf.name).to eq('test.pdf')
        expect(pdf.status).to eq('pending')
      end
    end

    context 'when CSS is provided' do
      let(:html_file) { Tempfile.new(['test', '.html']) }
      let(:css_file) { Tempfile.new(['test', '.css']) }
      let(:mock_response) do
        {
          'data' => {
            'id' => 123,
            'name' => 'test.pdf',
            'status' => 'pending',
            'download_url' => 'https://api.generatepdfs.com/pdfs/123/download/token',
            'created_at' => '2024-01-01T12:00:00.000000Z'
          }
        }
      end

      before do
        html_file.write('<html><body>Test</body></html>')
        html_file.close
        css_file.write('body { color: red; }')
        css_file.close

        stub_request(:post, "#{base_url}/pdfs/generate")
          .with(
            headers: {
              'Authorization' => "Bearer #{api_token}",
              'Content-Type' => 'application/json'
            },
            body: hash_including('html', 'css')
          )
          .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      after do
        html_file.unlink
        css_file.unlink
      end

      it 'includes CSS in the request' do
        pdf = client.generate_from_html(html_file.path, css_file.path)

        expect(pdf).to be_instance_of(GeneratePDFs::Pdf)
      end
    end

    context 'when images are provided' do
      let(:html_file) { Tempfile.new(['test', '.html']) }
      let(:image_file) { Tempfile.new(['test', '.png']) }
      let(:mock_response) do
        {
          'data' => {
            'id' => 123,
            'name' => 'test.pdf',
            'status' => 'pending',
            'download_url' => 'https://api.generatepdfs.com/pdfs/123/download/token',
            'created_at' => '2024-01-01T12:00:00.000000Z'
          }
        }
      end

      before do
        html_file.write('<html><body>Test</body></html>')
        html_file.close
        image_file.write('fake-image-content')
        image_file.close

        stub_request(:post, "#{base_url}/pdfs/generate")
          .with(
            headers: {
              'Authorization' => "Bearer #{api_token}",
              'Content-Type' => 'application/json'
            },
            body: hash_including('html', 'images')
          )
          .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      after do
        html_file.unlink
        image_file.unlink
      end

      it 'includes images in the request' do
        pdf = client.generate_from_html(html_file.path, nil, [
          {
            name: 'test.png',
            path: image_file.path
          }
        ])

        expect(pdf).to be_instance_of(GeneratePDFs::Pdf)
      end
    end

    context 'when API response is invalid' do
      let(:html_file) { Tempfile.new(['test', '.html']) }

      before do
        html_file.write('<html><body>Test</body></html>')
        html_file.close

        stub_request(:post, "#{base_url}/pdfs/generate")
          .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      after { html_file.unlink }

      it 'raises InvalidArgumentException' do
        expect do
          client.generate_from_html(html_file.path)
        end.to raise_error(GeneratePDFs::InvalidArgumentException, 'Invalid API response: missing data')
      end
    end

    context 'when API request fails' do
      let(:html_file) { Tempfile.new(['test', '.html']) }

      before do
        html_file.write('<html><body>Test</body></html>')
        html_file.close

        stub_request(:post, "#{base_url}/pdfs/generate")
          .to_return(status: 400, body: 'Bad Request', headers: { 'Content-Type' => 'text/plain' })
      end

      after { html_file.unlink }

      it 'raises RuntimeException' do
        expect do
          client.generate_from_html(html_file.path)
        end.to raise_error(GeneratePDFs::RuntimeException, /API request failed/)
      end
    end
  end

  describe '#generate_from_url' do
    context 'when URL is invalid' do
      it 'raises InvalidArgumentException' do
        expect do
          client.generate_from_url('not-a-valid-url')
        end.to raise_error(GeneratePDFs::InvalidArgumentException, 'Invalid URL: not-a-valid-url')
      end
    end

    context 'when successfully generating PDF from URL' do
      let(:mock_response) do
        {
          'data' => {
            'id' => 456,
            'name' => 'url-example.com-2024-01-01-12-00-00.pdf',
            'status' => 'pending',
            'download_url' => 'https://api.generatepdfs.com/pdfs/456/download/token',
            'created_at' => '2024-01-01T12:00:00.000000Z'
          }
        }
      end

      before do
        stub_request(:post, "#{base_url}/pdfs/generate")
          .with(
            headers: {
              'Authorization' => "Bearer #{api_token}",
              'Content-Type' => 'application/json'
            },
            body: hash_including('url' => 'https://example.com')
          )
          .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns a Pdf instance' do
        pdf = client.generate_from_url('https://example.com')

        expect(pdf).to be_instance_of(GeneratePDFs::Pdf)
        expect(pdf.id).to eq(456)
        expect(pdf.name).to eq('url-example.com-2024-01-01-12-00-00.pdf')
      end
    end
  end

  describe '#get_pdf' do
    context 'when ID is invalid' do
      it 'raises InvalidArgumentException for zero' do
        expect do
          client.get_pdf(0)
        end.to raise_error(GeneratePDFs::InvalidArgumentException, 'Invalid PDF ID: 0')
      end

      it 'raises InvalidArgumentException for negative' do
        expect do
          client.get_pdf(-1)
        end.to raise_error(GeneratePDFs::InvalidArgumentException, 'Invalid PDF ID: -1')
      end
    end

    context 'when successfully retrieving PDF by ID' do
      let(:mock_response) do
        {
          'data' => {
            'id' => 789,
            'name' => 'retrieved.pdf',
            'status' => 'completed',
            'download_url' => 'https://api.generatepdfs.com/pdfs/789/download/token',
            'created_at' => '2024-01-01T12:00:00.000000Z'
          }
        }
      end

      before do
        stub_request(:get, "#{base_url}/pdfs/789")
          .with(
            headers: {
              'Authorization' => "Bearer #{api_token}"
            }
          )
          .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns a Pdf instance' do
        pdf = client.get_pdf(789)

        expect(pdf).to be_instance_of(GeneratePDFs::Pdf)
        expect(pdf.id).to eq(789)
        expect(pdf.name).to eq('retrieved.pdf')
        expect(pdf.status).to eq('completed')
      end
    end

    context 'when API response is invalid' do
      before do
        stub_request(:get, "#{base_url}/pdfs/123")
          .to_return(status: 200, body: {}.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises InvalidArgumentException' do
        expect do
          client.get_pdf(123)
        end.to raise_error(GeneratePDFs::InvalidArgumentException, 'Invalid API response: missing data')
      end
    end
  end

  describe '#download_pdf' do
    context 'when successfully downloading PDF content' do
      let(:download_url) { 'https://api.generatepdfs.com/pdfs/123/download/token' }
      let(:pdf_content) { '%PDF-1.4 fake pdf content' }

      before do
        stub_request(:get, download_url)
          .with(
            headers: {
              'Authorization' => "Bearer #{api_token}"
            }
          )
          .to_return(status: 200, body: pdf_content, headers: { 'Content-Type' => 'application/pdf' })
      end

      it 'returns PDF content' do
        content = client.download_pdf(download_url)

        expect(content).to eq(pdf_content)
      end
    end

    context 'when download fails' do
      let(:download_url) { 'https://api.generatepdfs.com/pdfs/123/download/token' }

      before do
        stub_request(:get, download_url)
          .to_return(status: 404, body: 'Not Found', headers: { 'Content-Type' => 'text/plain' })
      end

      it 'raises RuntimeException' do
        expect do
          client.download_pdf(download_url)
        end.to raise_error(GeneratePDFs::RuntimeException, /Failed to download PDF/)
      end
    end
  end
end
