if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.start
end

require 'bundler/setup'

require 'test/unit'
require 'shoulda/context'
require 'turn'
require 'mocha/setup'
require 'vcr'

require 'rack/test'

require 'pickwick-api'

class Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Pickwick::API::Application
  end

  def setup
  end

  def teardown
  end

end
