require 'sinatra/base'

require 'active_model'
require 'virtus'
require 'elasticsearch/model'

require 'pickwick/elasticsearch/model/persistence'
require 'pickwick/elasticsearch/model/adapters/persistence'
require "pickwick/api/application"

require "pickwick/api/version"

module Pickwick
  module API
  end
end
