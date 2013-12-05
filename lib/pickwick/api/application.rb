module Pickwick
  module API
    class Application < Sinatra::Base
      include Models

      enable :logging

      helpers Helpers::RespondWith
      helpers Helpers::Common

      configure do
        mime_type :jsld, 'application/ld+json'
      end

      configure :development do
        enable :dump_errors
      end

      set(:permission) do |permission|
        condition do
          @consumer = Consumer.find_by_token(params[:token]) unless params[:token].blank?
          access_denied if @consumer.nil? || !@consumer.permission.send(permission)
        end
      end

      get '/' do
        respond_with do
          html { erb  :readme }
          json { json(application: 'Pickwick API', revision: Pickwick::API.revision) }
        end
      end

      register Store

      private
      def access_denied
        halt 401, json(error: 'Access denied')
      end

    end
  end
end
