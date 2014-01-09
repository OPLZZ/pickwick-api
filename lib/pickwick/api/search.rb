module Pickwick
  module API
    module Search
      extend Pickwick::API::Base
      include Models

      in_application do

        get "/vacancies", permission: :search do
          in_request do
            vacancies = Vacancy.search("*").records

            json(vacancies: vacancies.map(&:public_properties))
          end
        end

        get "/vacancies/:id", permission: :search do
          in_request do
            vacancy = Vacancy.find(params[:id]).first

            if vacancy
              json(vacancy: vacancy.public_properties)
            else
              halt 404, json(error: 'Not found')
            end
          end
        end

        post "/vacancies/bulk", permission: :search do
          in_request do
            vacancies = Vacancy.find(params[:ids])

            json(vacancies: vacancies.map(&:public_properties))
          end
        end

      end

    end

  end
end
