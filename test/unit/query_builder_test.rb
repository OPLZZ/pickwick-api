require 'test_helper'

module Pickwick
  module API
    module Models
      class QueryBuilderTest < Test::Unit::TestCase

        context "Query builder" do

          should "generate 'blank' query" do
            definition = QueryBuilder.new.to_hash

            assert_equal 'sum',   definition[:query][:function_score][:score_mode]
            assert_equal '30d',   definition[:query][:function_score][:functions][0][:gauss][:start_date][:scale]
            assert_equal 'now/d', definition[:query][:function_score][:functions][1][:filter][:range][:expiration_date][:lt]
            assert_not_nil        definition[:query][:function_score][:functions][2][:random_score][:seed]
          end

          should "add geo function when location parameter is presented" do
            definition = QueryBuilder.new(location: '50.102648,14.44616').to_hash

            assert_equal 50.102648, definition[:query][:function_score][:functions][0][:gauss][:'location.coordinates'][:origin][:lat]
            assert_equal 14.44616,  definition[:query][:function_score][:functions][0][:gauss][:'location.coordinates'][:origin][:lon]
          end

          should "add distance script field when location parameter is presented" do
            definition = QueryBuilder.new(location: '50.102648,14.44616').to_hash

            assert_not_nil '', definition[:script_fields][:distance][:script]
          end

          should "add employment type when type parameter is presented" do
            definition = QueryBuilder.new(employment_type: 'part-time').to_hash

            assert_equal 'part-time', definition[:query][:function_score][:functions][0][:filter][:not][:term][:employment_type]
            assert_equal -0.5,        definition[:query][:function_score][:functions][0][:boost_factor]
          end

          should "add remote when remote parameter is presented" do
            definition = QueryBuilder.new(remote: 'true').to_hash

            assert_equal true, definition[:query][:function_score][:functions][0][:filter][:not][:term][:remote]
            assert_equal -0.5, definition[:query][:function_score][:functions][0][:boost_factor]
          end

          should "search for user query when query parameter is presented" do
            definition = QueryBuilder.new(query: 'programmer').to_hash

            assert_equal 'programmer', definition[:query][:function_score][:query][:multi_match][:query]
            assert_equal [ "title",
                           "description",
                           "industry",
                           "contact.*",
                           "employer.*",
                           "employment_type",
                           "experience.*",
                           "location.*",
                           "publisher.*",
                           "responsibilities" ], definition[:query][:function_score][:query][:multi_match][:fields]
          end

          should "calculate `from`, `size` attributes to get desired result page" do
            definition = QueryBuilder.new.to_hash

            assert_equal 25, definition[:size]
            assert_equal 0,  definition[:from]

            definition = QueryBuilder.new(page: 3).to_hash

            assert_equal 25, definition[:size]
            assert_equal 50, definition[:from]

            definition = QueryBuilder.new(page: 3, per_page: 10).to_hash

            assert_equal 10, definition[:size]
            assert_equal 20, definition[:from]
          end

          should "use same seed as in parameters" do
            definition = QueryBuilder.new(seed: 123).to_hash

            assert_equal 123, definition[:query][:function_score][:functions][2][:random_score][:seed]
          end

          should "compose query from selected params" do
            definition = QueryBuilder.new(query: 'programmer', location: '50.102648,14.44616', employment_type: 'full-time', seed: 123, remote: 'false').to_hash

            assert_not_nil             definition[:script_fields][:distance][:script]
            assert_equal true,         definition[:_source]
            assert_equal 'sum',        definition[:query][:function_score][:score_mode]
            assert_equal 'programmer', definition[:query][:function_score][:query][:multi_match][:query]
            assert_equal 123,          definition[:query][:function_score][:functions].last[:random_score][:seed]
            assert_equal 6,            definition[:query][:function_score][:functions].size
          end

        end

      end
    end
  end
end
