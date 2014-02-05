module Elasticsearch
  module Model

    module Persistence

      # NOTE: `Virtus::Attribute.accepted_options` doesn't return :writer and :reader options without following line.
      #
      Virtus::Attribute.accept_options :writer, :reader

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

          extend  ClassMethods
          include InstanceMethods
        end
      end

      module ClassMethods

        def initialize_from_response(response)
          _source  = response.delete "_source"
          instance = self.new _source.merge(response)

          self.attribute_set.select { |a| a.options[:writer] == :private }.each do |attribute|
            instance.__set_property(attribute.name, _source[attribute.name.to_s])
          end

          instance.__set_property(:id,        response["_id"])
          instance.__set_property(:version,   response["_version"])
          instance.__set_property(:score,     response["_score"])
          instance.__set_property(:fields,    (response["fields"] || {}).symbolize_keys!)
          instance.__set_property(:persisted, true)

          instance
        end

        def property(name, type = nil, options = {})

          # Create attributes using Virtus
          #
          attribute(name, type, __get_virtus_options(options))
          # Set elasticsearch mapping
          #
          __elasticsearch__.mapping.indexes(name.to_sym, __get_elasticsearch_options(name, type, options))

          self
        end

        def create(attributes={})
          new(attributes).save
        end

        def find(*ids)
          docs     = Array(ids).flatten.map { |id| { _index: self.index_name, _id: id, _type: self.document_type } }
          response = __elasticsearch__.client.mget body: { docs: docs }

          response["docs"].map do |doc|
            self.initialize_from_response(doc) if doc["found"]
          end.compact
        end

        def __get_virtus_options(options)
          options.slice(*Virtus::Attribute.accepted_options)
        end

        def __get_elasticsearch_options(name, type, options)
          options              = options.except(*Virtus::Attribute.accepted_options)
          options[:type]     ||= __get_elasticsearch_type(type)

          nested_properties    = type.mapping.to_hash[name][:properties] if type.respond_to?(:mappings) rescue nil
          options[:properties] = nested_properties.deep_merge(options[:properties] || {}) if nested_properties

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
        attr_accessor :version, :persisted, :fields, :score

        def as_json(options = {})
          self.to_hash.as_json(options)
        end

        def as_indexed_json(options = {})
          except  = Array(options[:except])
          except |= [:id]
          as_json(options.merge(except: except))
        end

        def save
          return false unless valid?
          run_callbacks :save do
            unless persisted?
              run_callbacks :create do
                if response = __elasticsearch__.index_document
                  @id        = response["_id"]
                  @version   = response["_version"]
                  @persisted = true
                end
                response["_version"] ? self : false
              end
            else
              if response = __elasticsearch__.update_document
                @version = response["_version"]
              end
              response["_version"] ? self : false
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

        def __set_property(property, value)
          method = case
                   when self.respond_to?("#{property}=".to_sym)
                     "#{property}=".to_sym
                   when self.respond_to?("set_#{property}".to_sym)
                    "set_#{property}".to_sym
                   else
                     raise NoMethodError, "#{self.class} doesn't have setter method for #{property} attribute."
                   end

          self.send(method, value)
        end

      end
    end

  end
end
