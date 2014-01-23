require 'sinatra/base'
require 'rubykiq'

require 'rdiscount'
require 'pry' unless Sinatra::Base.production?

require 'active_model'
require 'virtus'
require 'elasticsearch/model'
require 'jbuilder'
require 'ruby-duration'

require 'pickwick/elasticsearch/model/persistence'
require 'pickwick/elasticsearch/model/adapters/persistence'

require 'pickwick/api/helpers/respond_with'
require 'pickwick/api/helpers/common'

require 'pickwick/api/models/consumer'
require 'pickwick/api/models/employer'
require 'pickwick/api/models/experience'
require 'pickwick/api/models/publisher'
require 'pickwick/api/models/coordinates'
require 'pickwick/api/models/location'
require 'pickwick/api/models/compensation'
require 'pickwick/api/models/contact'
require 'pickwick/api/models/vacancy'

require 'pickwick/api/base'
require 'pickwick/api/store'
require 'pickwick/api/search'
require 'pickwick/api/application'

require 'pickwick/api/version'

module Pickwick
  module API
    REVISION = `git --git-dir="#{File.dirname(__FILE__)}/../../.git" log -1 --pretty=%h`.strip rescue 'N/A'

    def self.revision
      REVISION
    end
  end
end

# Set elasticsearch client to ELASTICSEARCH_API_URL environment variable
#
Elasticsearch::Model.client = Elasticsearch::Client.new url: ENV["ELASTICSEARCH_API_URL"] || 'http://localhost:9200'

# Set redis client to SIDEKIQ_REDIS_URL environment variable
Rubykiq.url = ENV["SIDEKIQ_REDIS_URL"] || 'redis://localhost:6379'
