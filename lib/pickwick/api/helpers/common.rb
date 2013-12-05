module Pickwick
  module API
    module Helpers
      module Common

        def json(value)
          MultiJson.dump value, indent: 2
        end

      end
    end
  end
end
