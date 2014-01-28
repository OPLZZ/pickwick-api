module Pickwick
  module API
    module Presenters
      class Store
        include Helpers::Common

        attr_reader :results

        def initialize(results)
          @results = results
        end

        def as_json
          json(results: results.map { |r| { id: r[:id], version: r[:version], status: r[:status], errors: r[:errors] } })
        end

      end
    end
  end
end
