require 'test_helper'

module Pickwick
  module API
    module Models
      class VacancyTest < Test::Unit::TestCase

        context "When validating" do

          should "have title and description" do
            vacancy = FactoryGirl.build(:vacancy)
            assert vacancy.valid?

            vacancy.title = nil

            assert ! vacancy.valid?
          end

          should "have valid employment type" do
            vacancy = FactoryGirl.build(:vacancy)
            assert vacancy.valid?

            vacancy.employment_type = 'full_time'
            assert ! vacancy.valid?
          end

          should "have valid experience duration ISO format" do
            vacancy = FactoryGirl.build(:vacancy)
            vacancy.experience.duration = "P1Yys"

            assert ! vacancy.valid?
            assert_equal "not in valid ISO 8601 format (http://en.wikipedia.org/wiki/ISO_8601#Durations)", vacancy.errors.messages[:experience].first[:duration].first

            vacancy.experience.duration = "foobar"
            assert ! vacancy.valid?
          end

          should "have valid contact" do
            vacancy = FactoryGirl.build(:vacancy)
            vacancy.contact.email = "email"

            assert ! vacancy.valid?
            assert_equal "email is invalid", vacancy.errors.messages[:contact].first[:email].first

            vacancy.contact.email = nil
            vacancy.contact.phone = nil

            assert ! vacancy.valid?
            assert_equal "email or phone number required", vacancy.errors.messages[:contact].first[:base].first

            vacancy.contact.email = "email@example.com"
            assert vacancy.valid?
          end

        end

        context "When creating" do

          should "use generated id instead of passed one" do
            vacancy = Vacancy.new(id: '123')
            assert vacancy.id != '123'
          end

        end

        context "Instance" do

          setup do
            Time.stubs(:now).returns(Time.at(1386625470))

            @vacancy = FactoryGirl.build(:vacancy)
          end

          teardown do
            Time.unstub(:now)
          end

          should "have default expiration date set" do
            assert_not_nil @vacancy.expiration_date
            assert_equal "2014-01-08 21:44:30 UTC", @vacancy.expiration_date.to_s
          end

          should "have updated_at set before each save" do
            @elasticsearch_proxy = stub(index_document: {"_id" => 123, "_version" => 1, "ok" => true})
            @vacancy.stubs(:__elasticsearch__).returns(@elasticsearch_proxy)

            @vacancy.save
            assert_equal "2013-12-09 21:44:30 UTC", @vacancy.updated_at.to_s
          end

          should "have calculated id from vacancy properties" do
            @vacancy.title       = "Title"
            @vacancy.description = "Content"
            @vacancy.location    = Location.new(country: "Prague")
            @vacancy.start_date  = Time.now.utc

            @vacancy.__elasticsearch__.client.expects(:index).with do |options|
              assert_equal "8adad4682cd0c1a564f6a6ebc675b180b12637b5", options[:id]
            end.returns({})

            @vacancy.save
          end

        end

      end
    end
  end
end
