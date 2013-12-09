require 'sinatra/base'

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
require "pickwick/api/base"
require 'pickwick/api/store'
require "pickwick/api/application"

require "pickwick/api/version"

module Pickwick
  module API
    REVISION = `git --git-dir="#{File.dirname(__FILE__)}/../../.git" log -1 --pretty=%h`.strip rescue 'N/A'

    def self.revision
      REVISION
    end
  end
end
