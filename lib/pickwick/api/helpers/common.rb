module Pickwick
  module API
    module Helpers
      module Common

        def json(value)
          MultiJson.dump value, indent: 2
        end

        def in_request(&block)
          begin
            block.call
          rescue Exception => e
            error 500, json(error: e.class, description: e.message, backtrace: e.backtrace.first)
          end
        end

      end
    end
  end
end
