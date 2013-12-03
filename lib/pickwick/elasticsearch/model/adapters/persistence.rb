module Elasticsearch
  module Model
    module Adapters

      module Persistence

        Adapter.register self,
                         lambda { |klass| defined?(Elasticsearch::Model::Persistence) && klass.ancestors.include?(Elasticsearch::Model::Persistence) }

        module Records
          def records
            @results.results.map { |r| @klass.new(r._source.merge("id"        => r._id,
                                                                  "version"   => (r._version rescue nil),
                                                                  "persisted" => true)) }
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
