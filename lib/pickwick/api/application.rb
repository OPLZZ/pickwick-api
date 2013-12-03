module Pickwick
  module API
    class Application < Sinatra::Base

      enable   :logging

      configure :development do
        enable   :dump_errors
        register Sinatra::Reloader
      end

      get "/" do
        erb :readme
      end

    end
  end
end
