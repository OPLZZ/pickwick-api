module Pickwick
  module API
    module Models

      class Permission
        include Virtus.model

        attribute :search, Boolean, default: false
        attribute :store,  Boolean, default: false
      end

      class Consumer
        include Elasticsearch::Model::Persistence

        index_name 'pickwick-api-consumers'

        settings index: { number_of_shards: 1 }

        property :name, String

        property :description, String

        property :token, String,
                         index: 'not_analyzed',
                         default: lambda { |consumer, attribute| Digest::SHA1.hexdigest("#{Time.now.to_i}-#{rand(10000)}") }

        property :permission, Permission,
                              properties: {
                                read:  { type: 'boolean' },
                                write: { type: 'boolean' }
                              },
                              default: Permission.new

        def self.find_by_token(token)
          query = Jbuilder.encode do |json|
            json.query do
              json.match do
                json.token do
                  json.query token
                end
              end
            end
          end

          self.search(query).records.first
        end

      end
    end
  end
end
