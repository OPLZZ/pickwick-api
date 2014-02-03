module Pickwick
  module API
    module Models

      class Contact
        include Elasticsearch::Model::Persistence

        property :email, String, analyzer: 'names'
        property :name,  String, analyzer: 'names'
        property :phone, String

        validate do
          errors.add :base, "email or phone number required" unless email || phone
          errors.add :email, "email is invalid" if email.present? && !email.include?('@')
        end
      end
    end
  end
end
