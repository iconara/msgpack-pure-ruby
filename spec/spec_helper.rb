# encoding: utf-8

require 'bundler/setup'

unless ENV['COVERAGE'] == 'no'
  require 'coveralls'
  require 'simplecov'

  if ENV.include?('TRAVIS')
    Coveralls.wear!
    SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  end

  SimpleCov.start do
    add_group 'Source', 'lib'
  end
end

require 'msgpack'


RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
end