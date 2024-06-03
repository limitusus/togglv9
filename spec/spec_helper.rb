require 'simplecov'
require 'coveralls'
require 'pry'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start

require_relative 'togglv9_spec_helper'
require_relative '../lib/togglv9'

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.filter_run :focus
  config.filter_run_excluding :pro_account unless ENV['TOGGL_PRO_ACCOUNT']
  config.run_all_when_everything_filtered = true

  config.color = true
  config.tty = true
  config.formatter = :documentation

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:suite) do
    toggl = TogglV9::API.new(Testing::API_TOKEN)
    TogglV9SpecHelper.setUp(toggl) # start tests from known state
  end
end

class MockResponse
  # https://github.com/lostisland/faraday/blob/master/lib/faraday/response.rb

  attr_accessor :status, :headers, :body, :env

  def initialize(status, headers, body)
    @status = status
    @headers = headers
    @body = body
  end

  def success?
    @status == 200
  end
end

def mktemp_dir
  dir = File.join(Dir.pwd, "tmp-#{Time.now.to_f}")
  Dir.mkdir(dir)
  dir
end

def file_contains(filename, pattern, maxlen = 1000)
  expect(File.exist?(filename))
  contents = File.new(filename).sysread(maxlen)
  expect(contents).to match pattern
end

def file_is_pdf(filename)
  expect(File.exist?(filename))
  first_line = File.foreach(filename).first
  expect(first_line).to eq "%PDF-1.4\n"
end

def file_is_xls(filename)
  expect(File.exist?(filename))
  header = File.new(filename).sysread(8)
  expect(header).to eq ['D0CF11E0A1B11AE1'].pack('H*')
end

class Testing
  API_TOKEN = ENV['TOGGL_API_TOKEN'] || ENV['API_TOKEN'] || '4880adbe1bee9a241fa08070d33bd49f'
  EMAIL     = ENV['TOGGL_EMAIL'] || ENV['EMAIL'] || 'togglv9@mailinator.com'
  USERNAME  = ENV['TOGGL_USERNAME'] || ENV['USERNAME'] || 'togglv9'
  PASSWORD  = ENV['TOGGL_PASSWORD'] || ENV['PASSWORD'] || 'togglv9'
  USER_ID   = (ENV['TOGGL_USER_ID'] || ENV['USER_ID'] || 1820939).to_i

  OTHER_EMAIL    = ENV['OTHER_EMAIL']    || 'pr5zwux59w@snkmail.com'
  OTHER_USERNAME = ENV['OTHER_USERNAME'] || 'Pr5zwux59w'
  OTHER_USER_ID  = (ENV['OTHER_USER_ID'] || 2450739).to_i
end
