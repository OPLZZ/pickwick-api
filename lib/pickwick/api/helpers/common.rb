module Pickwick
  module API
    module Helpers
      module Common

        def json(value)
          MultiJson.dump value, indent: 2
        end

        def sha1(*values)
          values = Array(values).flatten
          Digest::SHA1.hexdigest(values.map { |value| value.respond_to?(:sha1) ? value.sha1 : value }.join(","))
        end

        def in_request(&block)
          begin
            block.call
          rescue Exception => e
            puts e.message, e.backtrace.join("\n")
            error 500, json(error: e.class, description: e.message, backtrace: e.backtrace.first)
          end
        end

      end
    end
  end
end
