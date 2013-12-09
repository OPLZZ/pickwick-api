require 'test_helper'

module Pickwick
  module API
    module Models
      class JobTest < Test::Unit::TestCase

        context "When validating" do

          should "have title and description" do
            job = FactoryGirl.build(:job)
            assert job.valid?

            job.title = nil

            assert ! job.valid?
          end

          should "have valid employment type" do
            job = FactoryGirl.build(:job)
            assert job.valid?

            job.employment_type = 'full_time'
            assert ! job.valid?
          end

          should "have valid experience duration ISO format" do
            job = FactoryGirl.build(:job)
            job.experience.duration = "P1Yys"

            assert ! job.valid?
            assert_equal "not in valid ISO 8601 format (http://en.wikipedia.org/wiki/ISO_8601#Durations)", job.errors.messages[:experience].first[:duration].first
          end

          should "have valid contact" do
            job = FactoryGirl.build(:job)
            job.contact.email = "email"

            assert ! job.valid?
            assert_equal "email is invalid", job.errors.messages[:contact].first[:email].first

            job.contact.email = nil
            job.contact.phone = nil

            assert ! job.valid?
            assert_equal "email or phone number required", job.errors.messages[:contact].first[:base].first
          end

        end

        context "Instance" do

          setup do
            Time.stubs(:now).returns(Time.at(1386625470))

            @job = FactoryGirl.build(:job)
          end

          teardown do
            Time.unstub(:now)
          end

          should "have default expiration date set" do
            assert_not_nil @job.expiration_date
            assert_equal "2014-01-08 21:44:30 UTC", @job.expiration_date.to_s
          end

          should "set updated at before each update" do
            @elasticsearch_proxy = stub(index_document: {"_id" => 123, "_version" => 1, "ok" => true})
            @job.stubs(:__elasticsearch__).returns(@elasticsearch_proxy)

            @job.save
            assert_equal "2013-12-09 21:44:30 UTC", @job.updated_at.to_s
          end

        end

      end
    end
  end
end
