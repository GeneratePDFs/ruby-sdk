# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GeneratePDFs::Pdf do
  let(:api_token) { 'test-api-token' }
  let(:client) { GeneratePDFs::GeneratePDFs.connect(api_token) }

  describe '.from_hash' do
    context 'with valid data' do
      let(:data) do
        {
          id: 123,
          name: 'test.pdf',
          status: 'completed',
          download_url: 'https://api.generatepdfs.com/pdfs/123/download/token',
          created_at: '2024-01-01T12:00:00.000000Z'
        }
      end

      it 'creates a Pdf instance' do
        pdf = described_class.from_hash(data, client)

        expect(pdf).to be_instance_of(described_class)
        expect(pdf.id).to eq(123)
        expect(pdf.name).to eq('test.pdf')
        expect(pdf.status).to eq('completed')
        expect(pdf.download_url).to eq('https://api.generatepdfs.com/pdfs/123/download/token')
      end
    end

    context 'when required fields are missing' do
      let(:data) do
        {
          id: 123
          # Missing other required fields
        }
      end

      it 'raises InvalidArgumentException' do
        expect do
          described_class.from_hash(data, client)
        end.to raise_error(GeneratePDFs::InvalidArgumentException, 'Invalid PDF data structure')
      end
    end

    context 'when created_at format is invalid' do
      let(:data) do
        {
          id: 123,
          name: 'test.pdf',
          status: 'completed',
          download_url: 'https://api.generatepdfs.com/pdfs/123/download/token',
          created_at: 'invalid-date-format'
        }
      end

      it 'raises InvalidArgumentException' do
        expect do
          described_class.from_hash(data, client)
        end.to raise_error(GeneratePDFs::InvalidArgumentException, /Invalid created_at format/)
      end
    end
  end

  describe 'getters' do
    let(:data) do
      {
        id: 456,
        name: 'document.pdf',
        status: 'pending',
        download_url: 'https://api.generatepdfs.com/pdfs/456/download/token',
        created_at: '2024-01-01T12:00:00.000000Z'
      }
    end

    let(:pdf) { described_class.from_hash(data, client) }

    it 'returns correct values' do
      expect(pdf.id).to eq(456)
      expect(pdf.name).to eq('document.pdf')
      expect(pdf.status).to eq('pending')
      expect(pdf.download_url).to eq('https://api.generatepdfs.com/pdfs/456/download/token')
      expect(pdf.created_at).to be_instance_of(Time)
    end
  end

  describe '#ready?' do
    context 'when status is completed' do
      let(:data) do
        {
          id: 123,
          name: 'test.pdf',
          status: 'completed',
          download_url: 'https://api.generatepdfs.com/pdfs/123/download/token',
          created_at: '2024-01-01T12:00:00.000000Z'
        }
      end

      it 'returns true' do
        pdf = described_class.from_hash(data, client)
        expect(pdf.ready?).to be true
      end
    end

    context 'when status is not completed' do
      let(:data) do
        {
          id: 123,
          name: 'test.pdf',
          status: 'pending',
          download_url: 'https://api.generatepdfs.com/pdfs/123/download/token',
          created_at: '2024-01-01T12:00:00.000000Z'
        }
      end

      it 'returns false' do
        pdf = described_class.from_hash(data, client)
        expect(pdf.ready?).to be false
      end
    end
  end

  describe '#download' do
    context 'when PDF is not ready' do
      let(:data) do
        {
          id: 123,
          name: 'test.pdf',
          status: 'pending',
          download_url: 'https://api.generatepdfs.com/pdfs/123/download/token',
          created_at: '2024-01-01T12:00:00.000000Z'
        }
      end

      it 'raises RuntimeException' do
        pdf = described_class.from_hash(data, client)

        expect do
          pdf.download
        end.to raise_error(GeneratePDFs::RuntimeException, 'PDF is not ready yet. Current status: pending')
      end
    end

    context 'when successfully downloading PDF content' do
      let(:data) do
        {
          id: 123,
          name: 'test.pdf',
          status: 'completed',
          download_url: 'https://api.generatepdfs.com/pdfs/123/download/token',
          created_at: '2024-01-01T12:00:00.000000Z'
        }
      end

      let(:pdf_content) { '%PDF-1.4 fake pdf content' }

      before do
        stub_request(:get, 'https://api.generatepdfs.com/pdfs/123/download/token')
          .with(
            headers: {
              'Authorization' => "Bearer #{api_token}"
            }
          )
          .to_return(status: 200, body: pdf_content, headers: { 'Content-Type' => 'application/pdf' })
      end

      it 'returns PDF content' do
        pdf = described_class.from_hash(data, client)
        content = pdf.download

        expect(content).to eq(pdf_content)
      end
    end
  end

  describe '#download_to_file' do
    let(:data) do
      {
        id: 123,
        name: 'test.pdf',
        status: 'completed',
        download_url: 'https://api.generatepdfs.com/pdfs/123/download/token',
        created_at: '2024-01-01T12:00:00.000000Z'
      }
    end

    let(:pdf_content) { '%PDF-1.4 fake pdf content' }
    let(:temp_file) { Tempfile.new(['test', '.pdf']) }

    before do
      temp_file.close
      stub_request(:get, 'https://api.generatepdfs.com/pdfs/123/download/token')
        .with(
          headers: {
            'Authorization' => "Bearer #{api_token}"
          }
        )
        .to_return(status: 200, body: pdf_content, headers: { 'Content-Type' => 'application/pdf' })
    end

    after { temp_file.unlink }

    it 'successfully saves PDF to file' do
      pdf = described_class.from_hash(data, client)
      result = pdf.download_to_file(temp_file.path)

      expect(result).to be true
      expect(File.exist?(temp_file.path)).to be true
      expect(File.binread(temp_file.path)).to eq(pdf_content)
    end
  end

  describe 'with different status values' do
    it 'handles different status values' do
      statuses = %w[pending processing completed failed]

      statuses.each do |status|
        data = {
          id: 123,
          name: 'test.pdf',
          status: status,
          download_url: 'https://api.generatepdfs.com/pdfs/123/download/token',
          created_at: '2024-01-01T12:00:00.000000Z'
        }

        pdf = described_class.from_hash(data, client)

        expect(pdf.status).to eq(status)
        expect(pdf.ready?).to eq(status == 'completed')
      end
    end
  end

  describe '#refresh' do
    let(:initial_data) do
      {
        id: 123,
        name: 'test.pdf',
        status: 'pending',
        download_url: 'https://api.generatepdfs.com/pdfs/123/download/token',
        created_at: '2024-01-01T12:00:00.000000Z'
      }
    end

    let(:mock_response) do
      {
        'data' => {
          'id' => 123,
          'name' => 'test.pdf',
          'status' => 'completed',
          'download_url' => 'https://api.generatepdfs.com/pdfs/123/download/new-token',
          'created_at' => '2024-01-01T12:00:00.000000Z'
        }
      }
    end

    before do
      stub_request(:get, 'https://api.generatepdfs.com/pdfs/123')
        .with(
          headers: {
            'Authorization' => "Bearer #{api_token}"
          }
        )
        .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'successfully updates PDF data' do
      pdf = described_class.from_hash(initial_data, client)

      # Verify initial state
      expect(pdf.status).to eq('pending')

      # Refresh the PDF
      refreshed_pdf = pdf.refresh

      # Verify refreshed state
      expect(refreshed_pdf).to be_instance_of(described_class)
      expect(refreshed_pdf.id).to eq(123)
      expect(refreshed_pdf.status).to eq('completed')
      expect(refreshed_pdf.download_url).to eq('https://api.generatepdfs.com/pdfs/123/download/new-token')
    end
  end
end
