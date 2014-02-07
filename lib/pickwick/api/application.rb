module Pickwick
  module API
    class Application < Sinatra::Base
      include Models

      enable :logging

      helpers  Helpers::Common

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

      before do
        headers( "Access-Control-Allow-Origin" => "*" )
      end

      get '/' do
        respond_with do
          html { erb  :readme }
          json { json(application: 'Pickwick API', revision: Pickwick::API.revision) }
        end
      end

      register Extensions::RespondWith
      register Store
      register Search

      private
      def access_denied
        text = 'Access denied'

        respond_with do
          html { halt 401, text }
          json { halt 401, json(error: text) }
          jsld { halt 401, json(error: text) }
        end
      end

    end
  end
end
