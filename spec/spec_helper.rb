require "codeclimate-test-reporter"
require 'rspec'
require 'factor/connector/test'
require 'factor/connector/runtime'

CodeClimate::TestReporter.start if ENV['CODECLIMATE_REPO_TOKEN']

require 'factor-connector-travis'

RSpec.configure do |c|
  c.include Factor::Connector::Test
end