require 'rails_helper'

RSpec.describe UserFile, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  it 'mounts the FileUploader on the :file attribute' do
    user_file = build(:user_file)
    expect(user_file.file).to be_a(FileUploader)
  end
end