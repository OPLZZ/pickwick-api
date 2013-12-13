module Pickwick
  module API
    module Models

      class Location
        include Elasticsearch::Model::Persistence

        property :street,      String
        property :city,        String
        property :region,      String

        # TODO: Check country format
        #
        property :country,     String
        property :coordinates, Coordinates, type: 'geo_point'
      end

    end
  end
end
