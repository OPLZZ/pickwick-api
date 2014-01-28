module Pickwick
  module API
    module Models

      class Vacancy
        include Elasticsearch::Model::Persistence

        DEFAULT_EXPIRATION = 30.days
        TYPES              = ['full-time', 'part-time', 'contract', 'temporary', 'seasonal', 'internship']
        ERRORS             = { 409 => 'similar document was already created by another API consumer',
                               404 => 'requested document was not found' }

        before_save :set_updated_at

        # TODO: add application `region` somehow
        #
        index_name 'pickwick-api-vacancies'

        settings index: { number_of_shards: 1 }

        property :id,                  String, accessor: :private, analyzer: 'keyword'
        property :consumer_id,         String, writer:   :private, analyzer: 'keyword'
        property :title,               String
        property :description,         String
        property :industry,            String, analyzer: 'keyword'
        property :responsibilities,    String
        property :number_of_positions, Integer

        property :employment_type,     String,  analyzer: 'keyword'
        property :remote,              Boolean, default: false

        property :location,            Location
        property :experience,          Experience
        property :employer,            Employer
        property :publisher,           Publisher
        property :contact,             Contact
        property :compensation,        Compensation

        property :start_date,          Time
        property :expiration_date,     Time, default: lambda { |vacancy, attribute| Time.now.utc + DEFAULT_EXPIRATION }
        property :created_at,          Time, default: lambda { |vacancy, attribute| Time.now.utc }
        property :updated_at,          Time, default: lambda { |vacancy, attribute| Time.now.utc } # Todo: try elasticsearch timestamp

        validates_presence_of :title,
                              :description,
                              :contact,
                              :location

        validates :employment_type, inclusion: { in: TYPES }, allow_nil: true

        validate do
          attributes.each do |attribute, value|
            errors.add attribute, value.errors.messages if value && value.respond_to?(:valid?) && !value.valid?
          end
        end

        def id
          @id ||= __computed_id
        end

        def set_id(id)
          @id = id
        end

        def set_consumer_id(consumer_id)
          @consumer_id = consumer_id
        end

        def public_properties
          properties = {
            id:       id,
            distance: fields[:distance] && fields[:distance].first ? fields[:distance].first.to_f : nil
          }.merge(as_json(except: [:consumer_id]))
        end

        def set_updated_at
          self.updated_at = Time.now.utc
        end

        private

        def __computed_id
          Digest::SHA1.hexdigest(attributes.slice(:title, :description, :start_date, :location).to_json)
        end

      end
    end
  end
end
