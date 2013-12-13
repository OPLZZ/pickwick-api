include Pickwick::API::Models

FactoryGirl.define do

  sequence(:random_title)       {|n| Faker::Lorem.sentence }
  sequence(:random_description) {|n| Faker::Lorem.paragraph }

  factory :vacancy do

    title            { generate(:random_title)       }
    description      { generate(:random_description) }
    responsibilities { generate(:random_description) }

    employment_type  { Vacancy::TYPES[rand(Vacancy::TYPES.size)] }

    remote           { [true, false][rand(2)] }

    location do
      Location.new street:      Faker::Address.street_name,
                   city:        Faker::Address.city,
                   region:      Faker::Address.city_prefix,
                   country:     Faker::Address.country,
                   coordinates: Coordinates.new(lat: Faker::Address.latitude, lon: Faker::Address.longitude)
    end

    experience do
      Experience.new description: generate(:random_description),
                     duration:    "P#{rand(3)}Y",
                     references:  [true, false][rand(2)]
    end

    employer do
      Employer.new name:    Faker::Name.name,
                   company: Faker::Company.name
    end

    publisher do
      Publisher.new name:    Faker::Name.name,
                    company: Faker::Company.name
    end

    contact do
      Contact.new name:  Faker::Name.name,
                  email: Faker::Internet.email,
                  phone: Faker::PhoneNumber.phone_number
    end

    compensation do
      amount = rand(1000)
      Compensation.new amount:            amount,
                       currency:          "CZK",
                       minimum:           0,
                       maximum:           amount,
                       compensation_type: Compensation::TYPES[rand(Compensation::TYPES.size)]

    end

    start_date { (Time.now + 1.month).utc }

    number_of_positions { rand(5) }

    to_create  { |instance| instance.save }

  end

end
