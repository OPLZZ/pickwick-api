module Pickwick
  module API
    module Models
      class QueryBuilder

        attr_accessor :params, :definition

        def initialize(params = {})
          @params          = params
          @definition      = {}
          @functions       = []

          __parse_params!
          __build!
        end

        def to_hash
          definition
        end

        def __parse_params!
          @location        = params[:location]        || params[:l]
          @query           = params[:query]           || params[:q]
          @employment_type = params[:employment_type] || params[:type] || params[:t]
          @seed            = params[:seed]            || __generate_seed

          @remote          = case (params[:remote] || params[:r]).to_s.strip.downcase
                             when 'true'
                               true
                             when 'false'
                               false
                             end if params[:remote] || params[:r]

          @latitude, @longitude = @location.split(",").map { |coordinate| coordinate.to_f } if @location
        end

        def __build!
          __add_distance        if @location
          __add_location        if @location
          __add_employment_type if @employment_type
          __add_remote          if @remote
          __add_start_date
          __add_expiration
          __add_random

          definition[:query] = {
            function_score: {
              query:      __fulltext_query,
              functions:  __scoring_functions,
              score_mode: 'sum'
            }
          }

          definition[:size] = 20

          self
        end

        def __fulltext_query
          case
          when @query
            { multi_match: {
                query:  @query,
                fields: [ "title",
                          "description",
                          "industry",
                          "contact.*",
                          "employer.*",
                          "employment_type",
                          "experience.*",
                          "location.*",
                          "publisher.*",
                          "responsibilities" ]
              }
            }
          else
            { match_all: {} }
          end
        end

        def __scoring_functions
          @functions
        end

        def __add_distance
          definition[:script_fields] = {
            distance: {
              script: "(doc['location.coordinates'].value != null) ? doc['location.coordinates'].arcDistanceInKm(#{@location}) : null"
            }
          }

          definition[:_source] = true
        end

        def __add_location
          @functions << {
            gauss: {
              :"location.coordinates" => {
                origin: {
                  lat: @latitude,
                  lon: @longitude
                },
                scale: "50km"
              }
            }
          }

          @functions << {
            filter: {
              missing: { field: "location.coordinates" },
            },
            boost_factor: -0.5
          }
        end

        def __add_employment_type
          @functions << {
            filter: {
              not: {
                term:   { employment_type: @employment_type },
                _cache: true
              }
            },
            boost_factor: -0.5
          }
        end

        def __add_remote
          @functions << {
            filter: {
              not: {
                term:   { remote: @remote },
                _cache: true
              }
            },
            boost_factor: -0.5
          }
        end

        def __add_start_date
          @functions << {
            gauss: {
              start_date: {
                scale:  "30d"
              }
            }
          }
        end

        def __add_expiration
          @functions << {
            filter: {
              range: {
                expiration_date: {
                  lt: "now/d"
                }
              }
            },
            boost_factor: -0.5
          }
        end

        def __add_random
          @functions << {
            random_score: { seed: @seed }
          }
        end

        def __generate_seed
          Time.now.to_i
        end

      end
    end
  end
end
