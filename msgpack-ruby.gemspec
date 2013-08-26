# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

require 'msgpack/version'


Gem::Specification.new do |spec|
  spec.name          = 'msgpack-ruby'
  spec.version       = MessagePack::VERSION
  spec.authors       = ['Theo Hultberg']
  spec.email         = ['theo@iconara.net']
  spec.description   = ''
  spec.summary       = ''
  spec.homepage      = ''
  spec.license       = 'Apache 2.0'

  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = %w[lib]
end
