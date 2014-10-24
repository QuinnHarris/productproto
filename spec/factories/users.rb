# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    sequence(:email) { |n| Faker::Internet.email }
    password p = Faker::Internet.password
    password_confirmation p
  end
end
