module Elasticsearch
  module Model
    module Adapters

      module Persistence

        Adapter.register self,
                         lambda { |klass| defined?(Elasticsearch::Model::Persistence) && klass.ancestors.include?(Elasticsearch::Model::Persistence) }

        module Records
          def records
            @results.results.map do |r|
              result      = r.to_hash
              _source     = result.delete "_source"
              instance    = @klass.new _source.merge(result).merge("persisted" => true)

              instance.__set_property(:id, result["_id"])

              @klass.attribute_set.select { |a| a.options[:writer] == :private }.each do |attribute|
                instance.__set_property(attribute.name, _source[attribute.name.to_s])
              end

              instance
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
