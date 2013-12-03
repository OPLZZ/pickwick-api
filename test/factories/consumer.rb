include Pickwick::API::Models

FactoryGirl.define do

  factory :consumer do

    sequence :name do |n|
      "API consumer #{n}"
    end

    factory :search_consumer do
      permission Permission.new search: true, store: false
    end

    factory :store_consumer do
      permission Permission.new search: false, store: true
    end

    factory :search_and_store_consumer do
      permission Permission.new search: true, store: true
    end    

  end

end
