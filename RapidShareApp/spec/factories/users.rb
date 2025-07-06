FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "testuser#{n}" }
    name { "Test User" }
    sequence(:email) { |n| "tester#{n}@example.com" }
    password { "Password123" }
    password_confirmation { "Password123" }
  end
end