module Pickwick
  module API
    module Models

      class Experience
        include Elasticsearch::Model::Persistence

        property :description, String
        property :duration,    String
        property :references,  Boolean

        validate do
          begin
            Duration.new(duration) if duration
          rescue ISO8601::Errors::UnknownPattern
            invalid = true
          end
          invalid ||= duration !~ /^P/
          errors.add :duration, "not in valid ISO 8601 format (http://en.wikipedia.org/wiki/ISO_8601#Durations)" if invalid
        end

      end

      class Employer
        include Elasticsearch::Model::Persistence

        property :name,    String
        property :company, String
      end

      class Publisher
        include Elasticsearch::Model::Persistence

        property :name,    String
        property :company, String
      end

      class Coordinates
        include Virtus.model

        attribute :lat, Float
        attribute :lon, Float
      end

      class Location
        include Elasticsearch::Model::Persistence

        property :street,      String
        property :city,        String
        property :region,      String

        # TODO: Check country format
        #
        property :country,     String
        property :coordinates, Coordinates, type: 'geo_point'
      end

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

      class Contact
        include Elasticsearch::Model::Persistence

        property :email, String
        property :name,  String
        property :phone, String

        validate do
          errors.add :base, "email or phone number required" unless email || phone
          errors.add :email, "email is invalid" if email.present? && !email.include?('@')
        end
      end

      class Job
        include Elasticsearch::Model::Persistence

        DEFAULT_EXPIRATION = 30.days
        TYPES              = ['full-time', 'part-time', 'contract', 'temporary', 'seasonal', 'internship']

        before_save :set_id, :set_updated_at

        # TODO: add application `region` somehow
        #
        index_name 'pickwick-api-jobs'

        settings index: { number_of_shards: 1 }

        property :title,            String
        property :description,      String
        property :industry,         String, index: 'not_analyzed'
        property :responsibilities, String

        property :vacancies,        Integer
        property :employment_type,  String,  index: 'not_analyzed'
        property :remote,           Boolean, default: false

        property :location,         Location
        property :experience,       Experience
        property :employer,         Employer
        property :publisher,        Publisher
        property :contact,          Contact
        property :compensation,     Compensation

        property :start_date,       Time
        property :expiration_date,  Time, default: lambda { |job, attribute| Time.now.utc + DEFAULT_EXPIRATION }
        property :created_at,       Time, default: lambda { |job, attribute| Time.now.utc }
        property :updated_at,       Time # Todo: try elasticsearch timestamp

        validates_presence_of :title,
                              :description,
                              :contact

        validates :employment_type, inclusion: { in: TYPES }, allow_nil: true

        validate do
          [:experience, :compensation, :contact].each do |property|
            errors.add property, self.send(property).errors.messages if self.send(property) && !self.send(property).valid?
          end
        end

        private

        def set_id
          self.id ||= __computed_id
        end

        def set_updated_at
          self.updated_at = Time.now.utc
        end

        def __computed_id
          Digest::SHA1.hexdigest(attributes.slice(:title, :description, :start_date, :location).to_json)
        end

      end
    end
  end
end
