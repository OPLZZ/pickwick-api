module Pickwick
  module API
    module Models

      class Location
        include Elasticsearch::Model::Persistence

        property :street,      String, analyzer: 'names'
        property :city,        String, analyzer: 'names'
        property :region,      String, analyzer: 'names'
        property :zip,         String

        # TODO: Check country format
        #
        property :country,     String, analyzer: 'names'
        property :coordinates, Coordinates, type: 'geo_point'
      end

    end
  end
end
