module Pickwick
  module API
    module Models
      class Employer
        include Elasticsearch::Model::Persistence

        property :name,    String
        property :company, String
      end
    end
  end
end
