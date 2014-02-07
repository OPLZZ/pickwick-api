module Pickwick
  module API
    module Extensions
      module RespondWith
        module Helper
          def respond_with(&block)
            responder = Responder.new(self)
            responder.instance_eval(&block)
            responder.perform
          end
        end

        def self.registered(app)
          app.helpers Helper

          app.set(:respond_to) do |*formats|
            condition do
              responder = Responder.new(self)
              mime_type = responder.__get_mime_type
              if formats.map { |format| settings.mime_types(format) }.flatten.include?(mime_type)
                content_type mime_type
              else
                responder.not_acceptable
              end
            end
          end
        end

        class Responder
          KNOWN_FORMATS = ['html', 'json', 'jsld']

          KNOWN_FORMATS.each do |format|
            define_method format do |&block|
              @app.settings.mime_types(format).each do |mime_type|
                @registered_mime_types[mime_type] = block
              end
            end
          end

          def initialize(app)
            @app                   = app
            @registered_mime_types = {}
            @default_mime_type     = 'application/json'
          end

          def perform
            mime_type = __get_mime_type

            if block = @registered_mime_types[mime_type]
              @app.content_type mime_type
              return @app.instance_eval(&block)
            end

            return not_acceptable
          end

          def not_acceptable
            @app.halt 406, "Not Acceptable"
          end

          def __get_mime_type
            mime_type = @app.content_type             ||
                        @app.request.preferred_type

            mime_type = @app.settings.mime_types(@app.params[:format]).first if @app.params[:format]

            mime_type = @default_mime_type if mime_type.to_s == '*/*'

            mime_type = mime_type.split(/\s*;\s*/, 2).first rescue nil
            mime_type
          end

        end

      end
    end
  end
end
