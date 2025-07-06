require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:user_files).dependent(:destroy) }
  end

  describe 'validations' do
    # Devise's :validatable module handles email and password validations
    # We only need to test our custom ones.
    subject { build(:user) }
    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username).case_insensitive }
  end
end