require 'test_helper'

module Pickwick
  module API
    module Models
      class ConsumerTest < Test::Unit::TestCase

        context "Consumer class" do

          should "be able to find consumer by token" do
            result = stub(records: [ FactoryGirl.build(:consumer, token: '123') ])

            Consumer.expects(:search).with do |search|
              search = MultiJson.load(search)

              assert_equal '123', search['query']['match']['token']['query']
            end.returns(result)

            assert_equal '123', Consumer.find_by_token('123').token
          end

        end

      end
    end
  end
end
