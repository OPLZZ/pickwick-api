require 'test_helper'

module Pickwick
  module API
    class ApplicationTest < IntegrationTestCase
      include Models

      context "Application" do

        should "render readme if content type is text/html" do
          header "ACCEPT", "text/html"
          get '/'

          assert last_response.ok?
          assert last_response.body.include?(RDiscount.new(File.read( File.join(app.settings.root, '..', '..', '..', 'README.md') )).to_html)
        end

        should "get application revision in JSON by default" do
          get '/'

          assert response.ok?
          assert_equal "Pickwick API", json(response.body)["application"]
          assert_not_nil json(response.body)["revision"]
        end

      end

      context "Store" do

        setup do
          @store_consumer  = FactoryGirl.create(:store_consumer)
          @search_consumer = FactoryGirl.create(:search_consumer)

          Consumer.__elasticsearch__.refresh_index!
        end

        context "Credentials" do
          should "deny access without valid token" do
            post '/store'

            assert_equal 401, response.status
            assert_equal "Access denied", json(response.body)["error"]
          end

          should "deny access for user without `store` permission" do
            post '/store', token: @search_consumer.token

            assert_equal 401, response.status
            assert_equal "Access denied", json(response.body)["error"]
          end

          should "allow access for user with proper permission" do
            post '/store', token: @store_consumer.token

            assert response.ok?
          end
        end

      end

    end
  end
end
