module Pickwick
  module API
    module Helpers
      module RespondWith

        class Responder
          KNOWN_TYPES = ['html', 'json', 'jsld']

          KNOWN_TYPES.each do |type|
            define_method type do |&block|
              @app.settings.mime_types(type).each do |mime_type|
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
            type      = mime_type.split(/\s*;\s*/, 2).first rescue nil

            if block = @registered_mime_types[type]
              @app.content_type mime_type
              return @app.instance_eval(&block)
            end

            @app.halt 406, "Not Acceptable"
          end

          private

          def __get_mime_type
            mime_type = @app.content_type             ||
                        @app.request.preferred_type

            mime_type = @default_mime_type if mime_type.to_s == '*/*'
            mime_type
          end

        end

        def respond_with(&block)
          responder = Responder.new(self)
          responder.instance_eval(&block)
          responder.perform
        end

      end
    end
  end
end
