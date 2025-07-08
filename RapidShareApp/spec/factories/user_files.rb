FactoryBot.define do
  factory :user_file do
    # This line tells CarrierWave to attach the actual test file
    # during the creation of the test object.
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test.txt'), 'text/plain') }

    association :user
  end
end