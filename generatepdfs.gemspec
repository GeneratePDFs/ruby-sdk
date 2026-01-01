# frozen_string_literal: true

require_relative 'lib/generatepdfs/version'

Gem::Specification.new do |spec|
  spec.name          = 'generatepdfs'
  spec.version       = GeneratePDFs::VERSION
  spec.authors       = ['GeneratePDFs']
  spec.email         = ['info@generatepdfs.com']

  spec.summary       = 'Ruby SDK for GeneratePDFs.com API'
  spec.description   = 'Ruby SDK for the GeneratePDFs.com API, your go-to place for HTML to PDF.'
  spec.homepage      = 'https://github.com/GeneratePDFs/ruby-sdk'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'README.md', 'LICENSE', 'CHANGELOG.md', 'CONTRIBUTING.md']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0.0'

  spec.add_dependency 'base64'
  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'mime-types', '~> 3.0'

  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'rubocop', '~> 1.57'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.25'
end
