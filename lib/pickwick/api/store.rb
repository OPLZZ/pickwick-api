module Pickwick
  module API
    module Store
      extend Pickwick::API::Base
      include Models

      in_application do

        post "/vacancies", permission: :store do
          begin
            payload = params[:payload].to_s.split("\n").map { |p| MultiJson.load(p, symbolize_keys: true) rescue nil }

            ids               = payload.map { |data| data[:id] rescue nil }.compact

            current_documents = ids.blank? ? [] : Vacancy.find(ids)

            documents = payload.each_with_index.map do |data, index|
              vacancy             = Vacancy.new(data)

              document            = {}
              document[:errors]   = {}
              document[:id]       = data[:id]
              document[:position] = index
              document[:valid]    = vacancy.valid?

              unless document[:valid]
                document[:errors] = vacancy.errors
                document[:status] = 400
              end

              if document[:id] && document[:valid]
                current = current_documents.find { |d| d.id == document[:id] }

                if current
                  if current.consumer_id != @consumer.id
                    document[:valid]           = false
                    document[:status]          = 409
                    document[:errors][:base] ||= []
                    document[:errors][:base]  << Vacancy::ERRORS[409]
                  end
                else
                  document[:valid]           = false
                  document[:status]          = 404
                  document[:errors][:base] ||= []
                  document[:errors][:base]  << Vacancy::ERRORS[404]
                end
              end

              document[:vacancy] = vacancy if document[:valid]

              document
            end

            filtered_documents = documents.group_by { |document| document[:valid] }

            invalid_documents  = filtered_documents[false] || []
            valid_documents    = filtered_documents[true]  || []

            unless valid_documents.blank?

              vacancies = valid_documents.map do |document|
                vacancy       = document[:vacancy]

                operation, id, data = if document[:id]
                  # TODO: send partial document instead of whole document
                  [ :update, document[:id], { doc: vacancy.as_indexed_json.merge(consumer_id: @consumer.id) } ]
                else
                  [ :create, vacancy.id, vacancy.as_indexed_json.merge(consumer_id: @consumer.id) ]
                end

                operation = document[:id] ? :update : :create
                id        = document[:id] ? document[:id] : vacancy.id

                { operation => { _index: vacancy.__elasticsearch__.index_name,
                                 _type:  vacancy.__elasticsearch__.document_type,
                                 _id:    id,
                                 data:   data } }
              end

              result = Vacancy.__elasticsearch__.client.bulk body: vacancies

              result["items"].each_with_index do |item, index|
                result = item["create"] || item["update"]

                valid_documents[index][:id]      = result["_id"]
                valid_documents[index][:version] = result["_version"]

                if result["ok"]
                  valid_documents[index][:status] = valid_documents[index][:version].to_i == 1 ? 201 : 200
                else
                  if result["error"].include?("document already exists")
                    valid_documents[index][:status]  = 409
                    valid_documents[index][:errors][:base] ||= []
                    valid_documents[index][:errors][:base]  << Vacancy::ERRORS[409]
                  else
                    valid_documents[index][:status]  = 500
                    valid_documents[index][:errors][:base] ||= []
                    valid_documents[index][:errors][:base]  << result["error"]
                  end
                end
              end

            end

            response = (invalid_documents + valid_documents).sort_by { |document| document[:position] }

            json(results: response.map { |r| { id: r[:id], version: r[:version], status: r[:status], errors: r[:errors] } })
          rescue Exception => e
            error 500, json(error: e.class, description: e.message, backtrace: e.backtrace.first)
          end
        end

      end

    end

  end
end
