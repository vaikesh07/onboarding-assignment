require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }

    it 'is invalid with a short password' do
      subject.password = 'short'
      expect(subject).not_to be_valid
      expect(subject.errors[:password]).to include('is too short (minimum is 8 characters)')
    end

    it 'is invalid without an uppercase letter in password' do
      subject.password = 'password123'
      expect(subject).not_to be_valid
    end

    it 'is invalid without a lowercase letter in password' do
      subject.password = 'PASSWORD123'
      expect(subject).not_to be_valid
    end

    it 'is invalid without a number in password' do
      subject.password = 'Password'
      expect(subject).not_to be_valid
    end
  end

  describe 'associations' do
    it { is_expected.to have_many(:user_files).dependent(:destroy) }
  end
end