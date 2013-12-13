module Pickwick
  module API
    module Models

      class Coordinates
        include Virtus.model

        attribute :lat, Float
        attribute :lon, Float
      end

    end
  end
end