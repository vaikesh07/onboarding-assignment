FactoryBot.define do
  factory :user_file do
    name { "test_file.txt" }
    content_type { "text/plain" }
    size { 1024 }
    data { "This is a test file." }
    association :user
  end
end