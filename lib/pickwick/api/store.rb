module Pickwick
  module API
    module Store
      extend Pickwick::API::Base

      in_application do

        post "/store", permission: :store do
        end

      end

    end

  end
end
