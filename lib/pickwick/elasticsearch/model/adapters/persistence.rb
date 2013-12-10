module Elasticsearch
  module Model
    module Adapters

      module Persistence

        Adapter.register self,
                         lambda { |klass| defined?(Elasticsearch::Model::Persistence) && klass.ancestors.include?(Elasticsearch::Model::Persistence) }

        module Records
          def records
            @results.results.map do |r|
              @klass.initialize_from_response(r.to_hash)
            end
          end
        end

        module Callbacks
        end

        module Importing
        end

      end

    end
  end
end
