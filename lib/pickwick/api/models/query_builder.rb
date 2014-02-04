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
          @query           = nil if @query.blank?
          @preference      = params[:preference]      || params[:p]
          @preference      = nil if @preference.blank?
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
          __add_distance        unless @location.blank?
          __add_location        unless @location.blank?
          __add_employment_type unless @employment_type.blank?
          __add_remote          unless @remote.blank?
          __add_start_date
          __add_random          if @query.blank? && @preference.blank?
          __add_score           unless @preference.blank?

          definition[:query] = {
            function_score: {
              query:      __fulltext_query,
              functions:  __scoring_functions,
              score_mode: 'avg',
              boost_mode: 'replace'
            }
          }

          definition[:filter] = {
            and: [
              { range: { expiration_date: { gte: "now/d" } } },
              { range: { start_date:      { gt:  "now-7d/d" } } }
            ]
          }

          definition[:size] = @per_page
          definition[:from] = (@page - 1) * @per_page

          self
        end

        def __fulltext_query
          match_all_definition = { match_all: {} }
          multi_match_query    = { multi_match: {
                                     operator: "AND",
                                     tie_breaker: 0.2,
                                     fields: [ "title",
                                               "description",
                                               "contact.*",
                                               "employer.*",
                                               "experience.description",
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

        def __add_score
          @functions << {
            script_score: {
              script: "log(_score+1)"
            }
          }
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
            exp: {
              :"location.coordinates" => {
                origin: {
                  lat: @latitude,
                  lon: @longitude
                },
                scale: "300km",
                decay: 0.1
              }
            }
          }

          # NOTE: When location.coordinates are missing, previous decay function returns 1 for these documents,
          #       so we need to subtract 1 to avoid boosting documents without GEO coordinates
          #
          @functions << {
            filter: {
              missing: { field: "location.coordinates" },
            },
            boost_factor: -1
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
            boost_factor: 0
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
            boost_factor: 0
          }
        end

        def __add_start_date
          @functions << {
            filter: {
              range: {
                start_date: {
                  lt: "now/d"
                }
              },
            },
            boost_factor: 0
          }
        end

        def __add_random
          @functions << {
            script_score: {
              params: {
                seed: @seed.to_i
              },
              script: "(abs(sin(doc['updated_at'].value + seed)) / 10) + 1"
            }
          }
        end

        def __generate_seed
          Time.now.to_i
        end

      end
    end
  end
end
