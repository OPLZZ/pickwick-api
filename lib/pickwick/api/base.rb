module Pickwick
  module API

    module Base
      def registered(app)
        app.instance_eval(&@blocks[self])
      end

      def in_application(&block)
        @blocks       ||= {}
        @blocks[self]   = block
      end
    end
  end
end
