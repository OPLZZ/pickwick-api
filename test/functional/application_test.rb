require 'test_helper'

module Pickwick
  module API
    class ApplicationTest < Test::Unit::TestCase

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

    end
  end
end
