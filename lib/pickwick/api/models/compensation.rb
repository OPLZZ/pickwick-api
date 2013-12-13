module Pickwick
  module API
    module Models

      class Compensation
        include Elasticsearch::Model::Persistence

        TYPES = ['hourly', 'monthly', 'weekly', 'daily', 'annual', 'fixed']

        property :amount,            Float

        # TODO: Check currency format
        #
        property :currency,          String
        property :maximum,           Float
        property :minimum,           Float
        property :compensation_type, String

        validates :compensation_type, inclusion: { in: TYPES }
      end

    end
  end
end
