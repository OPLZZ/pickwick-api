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
require 'faker'
Dir[File.dirname(__FILE__)+"/factories/*.rb"].each {|file| require file }

class IntegrationTestCase < Test::Unit::TestCase
  include Rack::Test::Methods

  alias response last_response

  def app
    Pickwick::API::Application
  end

  def setup
    super

    Consumer.index_name 'pickwick-api-consumers-test'
    Vacancy.index_name  'pickwick-api-vacancies-test'
    Consumer.__elasticsearch__.create_index!
    Vacancy.__elasticsearch__.create_index!
  end

  def teardown
    super

    Consumer.__elasticsearch__.delete_index!
    Vacancy.__elasticsearch__.delete_index!
  end

end

class Test::Unit::TestCase

  def json(json)
    MultiJson.load(json, symbolize_keys: true)
  end

end
