module Pickwick
  module API
    class Application < Sinatra::Base

      enable   :logging

      configure :development do
        enable   :dump_errors
      end

      get "/" do
        erb :readme
      end

    end
  end
end
