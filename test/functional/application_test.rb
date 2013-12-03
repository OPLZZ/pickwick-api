require 'test_helper'

module Pickwick
  module API
    class ApplicationTest < Test::Unit::TestCase

      context "Application" do

        should "render readme" do
          get '/'

          assert last_response.ok?
          assert last_response.body.include?(RDiscount.new(File.read( File.join(app.settings.root, '..', '..', '..', 'README.md') )).to_html)
        end

      end

    end
  end
end
