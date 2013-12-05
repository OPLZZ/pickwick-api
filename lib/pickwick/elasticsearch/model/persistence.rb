module Elasticsearch
  module Model

    module Persistence
      def self.included(base)
        base.class_eval do
          include ActiveModel::AttributeMethods
          include ActiveModel::Validations
          include ActiveModel::Serialization
          include ActiveModel::Serializers::JSON
          include ActiveModel::Naming
          include ActiveModel::Conversion
          include Elasticsearch::Model
          include Virtus.model

          extend  ActiveModel::Callbacks
          define_model_callbacks :create, :save, :destroy

          self.include_root_in_json = false

          extend  ClassMethods
          include InstanceMethods
        end
      end

      module ClassMethods

        def property(name, type = nil, options = {})

          # Create attributes using Virtus
          #
          attribute(name, type, __get_virtus_options(options))
          # Set elasticsearch mapping
          #
          __elasticsearch__.mapping.indexes(name.to_sym, __get_elasticsearch_options(type, options))

          self
        end

        def create(attributes={})
          new(attributes).save
        end

        def create_elasticsearch_index
          __elasticsearch__.client.indices.create index: self.index_name,
                                                  body:  {
                                                    settings: __elasticsearch__.settings.to_hash,
                                                    mappings: __elasticsearch__.mappings.to_hash
                                                  }
        end

        def delete_elasticsearch_index
          __elasticsearch__.client.indices.delete index: self.index_name
        end

        def refresh_elasticsearch_index
          __elasticsearch__.client.indices.refresh index: self.index_name
        end

        def __get_virtus_options(options)
          options.slice(*Virtus::Attribute.accepted_options)
        end

        def __get_elasticsearch_options(type, options)  
          options          = options.except(*Virtus::Attribute.accepted_options)
          options[:type] ||= __get_elasticsearch_type(type)
          options
        end

        def __get_elasticsearch_type(type)
          type       = type[0] if type.is_a?(Array)
          type_class = type.is_a?(Class) ? type : type.class
          return case
          when [ String, Integer, Float, Virtus::Attribute::Boolean ].any? { |t| type_class == t }
            type_class.to_s.demodulize.downcase
          when [ Date, DateTime, Time ].find { |t| type_class == t }
            'date'
          when type_class == Hash || type_class.instance_methods.include?(:to_hash)
            'object'
          end
        end

      end

      module InstanceMethods
        attr_accessor :id, :version, :persisted

        def save
          run_callbacks :save do
            unless persisted?
              run_callbacks :create do
                if response = __elasticsearch__.index_document
                  @id        = response["_id"]
                  @version   = response["_version"]
                  @persisted = true
                end
                response["ok"] ? self : false
              end
            else
              if response = __elasticsearch__.update_document
                @version = response["_version"]
              end
              response["ok"] ? self : false
            end
          end
        end

        def destroy
          run_callbacks :destroy do
            __elasticsearch__.delete_document
            @destroyed = true
            @persisted = false
          end
          self.freeze
        end

        def destroyed?
          !!@destroyed
        end

        def persisted?
          !!@persisted && !destroyed?
        end

      end
    end

  end
end
