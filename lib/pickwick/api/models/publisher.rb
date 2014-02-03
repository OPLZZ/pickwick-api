module Pickwick
  module API
    module Models

      class Publisher
        include Elasticsearch::Model::Persistence

        property :name,    String, analyzer: 'names'
        property :company, String, analyzer: 'names'
      end

    end
  end
end
