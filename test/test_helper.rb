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
require 'pry'

require 'rack/test'

require 'pickwick-api'

require 'factory_girl'
Dir[File.dirname(__FILE__)+"/factories/*.rb"].each {|file| require file }

class IntegrationTestCase < Test::Unit::TestCase
  include Rack::Test::Methods

  alias response last_response

  def app
    Pickwick::API::Application
  end

  def setup
    super

    Consumer.index_name 'consumers_test'
    Consumer.__elasticsearch__.create_index!
  end

  def teardown
    super

    Consumer.__elasticsearch__.delete_index!
  end

end

class Test::Unit::TestCase

  def json(json)
    MultiJson.load(json)
  end

end
