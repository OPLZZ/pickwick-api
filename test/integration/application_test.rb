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

        should "respond with 406 status code if unknown mime type is requested" do
          header "ACCEPT", "uknown"

          get '/'

          assert_equal 406, response.status
          assert_equal "Not Acceptable", response.body
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

          should "return error message if something goes wrong" do
            post 'store', token: @store_consumer.token, payload: '---'
            assert_equal 500, response.status
          end
        end

        context "Saving job offers" do

          setup do
            Time.stubs(:now).returns(Time.at(1386625470))
            @consumer = FactoryGirl.create(:store_consumer)

            Consumer.__elasticsearch__.refresh_index!
          end

          teardown do
            Time.unstub(:now)
          end

          should "create new documents with consumer id" do
            job = FactoryGirl.build(:job)
            post '/store', token: @store_consumer.token, payload: job.as_indexed_json(except: [:consumer_id, :created_at, :updated_at]).to_json

            persisted_job = Job.find(json(response.body)["results"].first["id"]).first

            assert response.ok?

            assert_equal @store_consumer.id, persisted_job.consumer_id
            assert_equal job.title,       persisted_job.title
            assert_equal job.description, persisted_job.description
          end

          should "not modify job from other API consumer" do
            job = FactoryGirl.build(:job)
            job.set_consumer_id "123"
            job.save
            Job.__elasticsearch__.refresh_index!

            post '/store', token: @consumer.token, payload: job.as_indexed_json.to_json
            result = json(response.body)["results"].first

            assert response.ok?
            assert_equal 409,              result["status"]
            assert_equal Job::ERRORS[409], result["errors"]["base"].first
          end

          should "update already saved document" do
            job = FactoryGirl.build(:job)
            job.set_consumer_id @consumer.id
            job.save
            Job.__elasticsearch__.refresh_index!

            post '/store', token: @consumer.token, payload: job.as_indexed_json.merge(title: 'changed title', expiration_date: Time.now + 1.day, id: job.id).to_json
            result = json(response.body)["results"].first

            Job.__elasticsearch__.refresh_index!
            job = Job.find(result["id"]).first

            assert response.ok?
            assert_equal "changed title",           job.title
            assert_equal "2013-12-10 21:44:30 UTC", job.expiration_date.to_s
            assert_equal 2,                         job.version
          end

          should "not save invalid document" do
            post '/store', token: @consumer.token, payload: Job.new.as_indexed_json.to_json
            result = json(response.body)["results"].first

            assert response.ok?
            assert_equal 400, result["status"]
            assert_equal ["can't be blank"], result["errors"]["title"]
          end

          should "not allow to take ownership" do
            job = FactoryGirl.build(:job)
            job.set_consumer_id '123'
            job.save
            Job.__elasticsearch__.refresh_index!

            post '/store', token: @consumer.token, payload: job.as_indexed_json.merge(consumer_id: @consumer.id, id: job.id).to_json
            result = json(response.body)["results"].first

            assert response.ok?
            assert_equal 409, result["status"]
            assert_equal job.consumer_id, Job.find(result["id"]).first.consumer_id
          end

          should "respond with elasticsearch error if persisting failed" do
            Job.__elasticsearch__.client.expects(:bulk).returns("items" => [ { "create" => {"error" => "some elasticsearch error"}}])

            post '/store', token: @consumer.token, payload: FactoryGirl.build(:job).as_indexed_json.to_json
            result = json(response.body)["results"].first

            assert response.ok?
            assert_equal 500,                        result["status"]
            assert_equal "some elasticsearch error", result["errors"]["base"].first
          end

          should "respond with correct order" do
            new_job          = FactoryGirl.build(:job)
            existing_job     = FactoryGirl.build(:job)
            existing_job.set_consumer_id @consumer.id
            existing_job.save
            invalid_job      = Job.new
            non_existing_job = FactoryGirl.build(:job)
            someones_job     = FactoryGirl.build(:job)
            someones_job.set_consumer_id "123"
            someones_job.save
            Job.__elasticsearch__.refresh_index!

            payload = [ existing_job.as_indexed_json.merge(id: existing_job.id).to_json,
                        invalid_job.as_indexed_json.to_json,
                        new_job.as_indexed_json.to_json,
                        someones_job.as_indexed_json.merge(id: someones_job.id).to_json,
                        non_existing_job.as_indexed_json.merge(id: non_existing_job.id).to_json ].join("\n")

            post '/store', token: @consumer.token, payload: payload

            r = json(response.body)

            assert response.ok?

            # First document was existing one, should be updated
            #
            assert_equal existing_job.id, r["results"][0]["id"]
            assert_equal 2,               r["results"][0]["version"]
            assert_equal 200,             r["results"][0]["status"]

            # Second document was invalid, should return errors
            #
            assert_nil r["results"][1]["id"]
            assert_equal 400,              r["results"][1]["status"]
            assert_equal 4,                r["results"][1]["errors"].keys.size
            assert_equal "can't be blank", r["results"][1]["errors"]["title"].first

            # Third document was new one, should be stored
            #
            assert_not_nil    r["results"][2]["id"]
            assert_equal 1,   r["results"][2]["version"]
            assert_equal 201, r["results"][2]["status"]

            # Fourth document was someone else's, should return error
            #
            assert_not_nil                 r["results"][3]["id"]
            assert_equal 409,              r["results"][3]["status"]
            assert_equal Job::ERRORS[409], r["results"][3]["errors"]["base"].first

            # Fifth document is not in the index (expired, deleted), should return error
            #
            assert_equal non_existing_job.id, r["results"][4]["id"]
            assert_equal 404,                 r["results"][4]["status"]
            assert_equal Job::ERRORS[404],    r["results"][4]["errors"]["base"].first
          end

        end

      end

    end
  end
end
