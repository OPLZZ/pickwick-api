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
