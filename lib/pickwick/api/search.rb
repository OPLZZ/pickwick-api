module Pickwick
  module API
    module Search
      extend Pickwick::API::Base
      include Models

      in_application do

        get "/vacancies", permission: :search do
          begin
            vacancies = Vacancy.search("*").records

            json(vacancies: vacancies.map(&:public_properties))
          rescue Exception => e
            error 500, json(error: e.class, description: e.message, backtrace: e.backtrace.first)
          end
        end

        get "/vacancies/:id", permission: :search do
          begin
            vacancy = Vacancy.find(params[:id]).first

            if vacancy
              json(vacancy: vacancy.public_properties)
            else
              halt 404, json(error: 'Not found')
            end

          rescue Exception => e
            error 500, json(error: e.class, description: e.message, backtrace: e.backtrace.first)
          end
        end

      end

    end

  end
end
