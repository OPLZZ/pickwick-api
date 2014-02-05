module Pickwick
  module API
    module Models
      class QueryBuilder

        attr_accessor :params, :definition, :page, :per_page, :seed

        def initialize(params = {})
          @params          = params.symbolize_keys!
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
          @preference      = params[:preference]      || params[:p]
          @employment_type = params[:employment_type] || params[:type] || params[:t]
          @seed            = params[:seed]            || __generate_seed

          @remote          = case (params[:remote] || params[:r]).to_s.strip.downcase
                             when 'true'
                               true
                             when 'false'
                               false
                             end if params[:remote] || params[:r]

          @latitude, @longitude = @location.split(",").map { |coordinate| coordinate.to_f } if @location

          @page     = (params[:page]     || 1).to_i
          @per_page = (params[:per_page] || 25).to_i
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

          definition[:size] = @per_page
          definition[:from] = (@page - 1) * @per_page

          self
        end

        def __fulltext_query
          match_all_definition = { match_all: {} }
          multi_match_query    = { multi_match: {
                                     operator: "AND",
                                     fields: [ "title",
                                               "description",
                                               "industry",
                                               "contact.*",
                                               "employer.*",
                                               "employment_type",
                                               "experience.*",
                                               "location.*",
                                               "publisher.*",
                                               "responsibilities" ]} }

          case
          when @query && @preference
            query            = multi_match_query.deep_merge(multi_match: { query: @query.strip })
            preference_query = { bool: {
                                        should: [
                                          multi_match_query.deep_merge(multi_match: { query: @preference.strip, operator: "OR" }),
                                          match_all_definition
                                        ],
                                        minimum_number_should_match: 1
                                      }
                                    }

            return { bool: { must: [ query, preference_query ] } }
          when @query
            return multi_match_query.deep_merge(multi_match: { query: @query.strip })
          when @preference
            return { bool: { should: [ multi_match_query.deep_merge(multi_match: { query: @preference.strip, operator: "OR" }),
                                       match_all_definition ] } }
          else
            return match_all_definition
          end
        end

        def __scoring_functions
          @functions
        end

        def __add_distance
          definition[:script_fields] = {
            distance: {
              script: "(!doc['location.coordinates'].empty && doc['location.coordinates'].value != null) ? doc['location.coordinates'].arcDistanceInKm(#{@location}) : null"
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
            boost_factor: -1.25
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
            boost_factor: -0.25
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
            boost_factor: -0.25
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

        # TODO: Move to filter?
        #
        def __add_expiration
          @functions << {
            filter: {
              range: {
                expiration_date: {
                  lt: "now/d"
                }
              },
            },
            boost_factor: -0.25
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
