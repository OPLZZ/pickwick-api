module Pickwick
  module API
    module Presenters
      class Search
        include Helpers::Common

        attr_reader :vacancies

        def initialize(vacancies)
          @vacancies = vacancies
        end

        def as_json
          json(vacancies: vacancies.map(&:public_properties))
        end

      end
    end
  end
end
