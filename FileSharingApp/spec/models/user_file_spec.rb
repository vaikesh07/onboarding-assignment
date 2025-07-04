require 'rails_helper'

RSpec.describe UserFile, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe '#generate_share_token' do
    let(:user_file) { create(:user_file) }

    it 'generates a token when shareable is turned on' do
      expect {
        user_file.update(shareable: true)
      }.to change { user_file.share_token }.from(nil).to(be_a(String))
    end

    it 'clears the token when shareable is turned off' do
      user_file.update(shareable: true) # First, turn it on
      expect {
        user_file.update(shareable: false)
      }.to change { user_file.share_token }.to(nil)
    end
  end
end