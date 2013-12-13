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

    end
  end
end
