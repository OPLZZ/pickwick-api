module Pickwick
  module API
    class Application < Sinatra::Base
      include Models

      enable :logging

      helpers Helpers::RespondWith

      configure do
        mime_type :jsld, 'application/ld+json'
      end

      configure :development do
        enable :dump_errors
      end
      get '/' do
        respond_with do
          html { erb  :readme }
          json { json(application: 'Pickwick API', revision: Pickwick::API.revision) }
        end
      end

      end

    end
  end
end
