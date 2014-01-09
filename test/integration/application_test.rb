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
          assert_equal "Pickwick API", json(response.body)[:application]
          assert_not_nil json(response.body)[:revision]
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
            post '/vacancies'

            assert_equal 401, response.status
            assert_equal "Access denied", json(response.body)[:error]
          end

          should "deny access for user without `store` permission" do
            post '/vacancies', token: @search_consumer.token

            assert_equal 401, response.status
            assert_equal "Access denied", json(response.body)[:error]
          end

          should "allow access for user with proper permission" do
            post '/vacancies', token: @store_consumer.token
            assert response.ok?
          end

          should "return error message if something goes wrong" do
            post '/vacancies', token: @store_consumer.token, payload: '---'
            assert_equal 500, response.status
          end
        end

        context "Saving vacancy offers" do

          setup do
            Time.stubs(:now).returns(Time.at(1386625470))
            @consumer = FactoryGirl.create(:store_consumer)

            Consumer.__elasticsearch__.refresh_index!
          end

          teardown do
            Time.unstub(:now)
          end

          should "create new documents with consumer id" do
            vacancy = FactoryGirl.build(:vacancy)
            post '/vacancies', token: @store_consumer.token, payload: vacancy.as_indexed_json(except: [:consumer_id, :created_at, :updated_at]).to_json

            persisted_vacancy = Vacancy.find(json(response.body)[:results].first[:id]).first

            assert response.ok?

            assert_equal @store_consumer.id,  persisted_vacancy.consumer_id
            assert_equal vacancy.title,       persisted_vacancy.title
            assert_equal vacancy.description, persisted_vacancy.description
          end

          should "not modify vacancy from other API consumer" do
            vacancy = FactoryGirl.build(:vacancy)
            vacancy.set_consumer_id "123"
            vacancy.save
            Vacancy.__elasticsearch__.refresh_index!

            post '/vacancies', token: @consumer.token, payload: vacancy.as_indexed_json.to_json
            result = json(response.body)[:results].first

            assert response.ok?
            assert_equal 409,                  result[:status]
            assert_equal Vacancy::ERRORS[409], result[:errors][:base].first
          end

          should "update already saved document" do
            vacancy = FactoryGirl.build(:vacancy)
            vacancy.set_consumer_id @consumer.id
            vacancy.save
            Vacancy.__elasticsearch__.refresh_index!

            post '/vacancies', token: @consumer.token, payload: vacancy.as_indexed_json.merge(title: 'changed title', expiration_date: Time.now + 1.day, id: vacancy.id).to_json
            result = json(response.body)[:results].first

            Vacancy.__elasticsearch__.refresh_index!
            vacancy = Vacancy.find(result[:id]).first

            assert response.ok?
            assert_equal "changed title",           vacancy.title
            assert_equal "2013-12-10 21:44:30 UTC", vacancy.expiration_date.to_s
            assert_equal 2,                         vacancy.version
          end

          should "not save invalid document" do
            post '/vacancies', token: @consumer.token, payload: Vacancy.new.as_indexed_json.to_json
            result = json(response.body)[:results].first

            assert response.ok?
            assert_equal 400, result[:status]
            assert_equal ["can't be blank"], result[:errors][:title]
          end

          should "not allow to take ownership" do
            vacancy = FactoryGirl.build(:vacancy)
            vacancy.set_consumer_id '123'
            vacancy.save
            Vacancy.__elasticsearch__.refresh_index!

            post '/vacancies', token: @consumer.token, payload: vacancy.as_indexed_json.merge(consumer_id: @consumer.id, id: vacancy.id).to_json
            result = json(response.body)[:results].first

            assert response.ok?
            assert_equal 409, result[:status]
            assert_equal vacancy.consumer_id, Vacancy.find(result[:id]).first.consumer_id
          end

          should "respond with elasticsearch error if persisting failed" do
            Vacancy.__elasticsearch__.client.expects(:bulk).returns("items" => [ { "create" => {"error" => "some elasticsearch error"}}])

            post '/vacancies', token: @consumer.token, payload: FactoryGirl.build(:vacancy).as_indexed_json.to_json
            result = json(response.body)[:results].first

            assert response.ok?
            assert_equal 500,                        result[:status]
            assert_equal "some elasticsearch error", result[:errors][:base].first
          end

          should "respond with correct order" do
            new_vacancy          = FactoryGirl.build(:vacancy)
            existing_vacancy     = FactoryGirl.build(:vacancy)
            existing_vacancy.set_consumer_id @consumer.id
            existing_vacancy.save
            invalid_vacancy      = Vacancy.new
            non_existing_vacancy = FactoryGirl.build(:vacancy)
            someones_vacancy     = FactoryGirl.build(:vacancy)
            someones_vacancy.set_consumer_id "123"
            someones_vacancy.save
            Vacancy.__elasticsearch__.refresh_index!

            payload = [ existing_vacancy.as_indexed_json.merge(id: existing_vacancy.id).to_json,
                        invalid_vacancy.as_indexed_json.to_json,
                        new_vacancy.as_indexed_json.to_json,
                        someones_vacancy.as_indexed_json.merge(id: someones_vacancy.id).to_json,
                        non_existing_vacancy.as_indexed_json.merge(id: non_existing_vacancy.id).to_json ].join("\n")

            post '/vacancies', token: @consumer.token, payload: payload

            r = json(response.body)

            assert response.ok?

            # First document was existing one, should be updated
            #
            assert_equal existing_vacancy.id, r[:results][0][:id]
            assert_equal 2,               r[:results][0][:version]
            assert_equal 200,             r[:results][0][:status]

            # Second document was invalid, should return errors
            #
            assert_nil r[:results][1][:id]
            assert_equal 400,              r[:results][1][:status]
            assert_equal 4,                r[:results][1][:errors].keys.size
            assert_equal "can't be blank", r[:results][1][:errors][:title].first

            # Third document was new one, should be stored
            #
            assert_not_nil    r[:results][2][:id]
            assert_equal 1,   r[:results][2][:version]
            assert_equal 201, r[:results][2][:status]

            # Fourth document was someone else's, should return error
            #
            assert_not_nil                     r[:results][3][:id]
            assert_equal 409,                  r[:results][3][:status]
            assert_equal Vacancy::ERRORS[409], r[:results][3][:errors][:base].first

            # Fifth document is not in the index (expired, deleted), should return error
            #
            assert_equal non_existing_vacancy.id, r[:results][4][:id]
            assert_equal 404,                     r[:results][4][:status]
            assert_equal Vacancy::ERRORS[404],    r[:results][4][:errors][:base].first
          end

        end

        context "Search" do
          setup do
            @store_consumer  = FactoryGirl.create(:store_consumer)
            @search_consumer = FactoryGirl.create(:search_consumer)

            Consumer.__elasticsearch__.refresh_index!
          end

          context "Credentials" do
            should "deny access without valid token" do
              get '/vacancies'

              assert_equal 401, response.status
              assert_equal "Access denied", json(response.body)[:error]
            end

            should "deny access for user without `store` permission" do
              get '/vacancies', token: @store_consumer.token

              assert_equal 401, response.status
              assert_equal "Access denied", json(response.body)[:error]
            end

            should "allow access for user with proper permission" do
              get '/vacancies', token: @search_consumer.token
              assert response.ok?
            end
          end

          context "Getting vacancy by id" do

            setup do
              @vacancy         = FactoryGirl.create(:vacancy)
              @another_vacancy = FactoryGirl.create(:vacancy)
              Vacancy.__elasticsearch__.refresh_index!
            end

            should "return vacancy by its id" do
              get "/vacancies/#{@vacancy.id}", token: @search_consumer.token

              r = json(response.body)

              assert response.ok?
              assert_equal @vacancy.id,    r[:vacancy][:id]
              assert_equal @vacancy.title, r[:vacancy][:title]
              assert_nil   r[:vacancy][:consumer_id]
            end

            should "return 'not found' error if vacancy not found by id" do
              get "/vacancies/123", token: @search_consumer.token

              r = json(response.body)

              assert_equal 404,         response.status
              assert_equal "Not found", r[:error]
            end

            should "return vacancies by multiple ids (by calling bulk endpoint)" do
              post "/vacancies/bulk", ids: [@another_vacancy.id, @vacancy.id, '123'], token: @search_consumer.token

              r = json(response.body)

              assert response.ok?

              assert_equal @another_vacancy.id,    r[:vacancies].first[:id]
              assert_equal @another_vacancy.title, r[:vacancies].first[:title]

              assert_equal @vacancy.id,    r[:vacancies].last[:id]
              assert_equal @vacancy.title, r[:vacancies].last[:title]
            end

          end

          context "Searching for vacancies" do
            setup do
              @vacancies = FactoryGirl.create_list(:vacancy, 10)
              Vacancy.__elasticsearch__.refresh_index!
            end

            should "return array of vacancies" do
              get "/vacancies", token: @search_consumer.token

              r = json(response.body)

              assert response.ok?
              assert_equal 10, r[:vacancies].size
              assert_not_nil r[:vacancies].first[:title]
              assert_nil     r[:vacancies].first[:consumer_id]
            end

          end

        end
      end
    end
  end
end
