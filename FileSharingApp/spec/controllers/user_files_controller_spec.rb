require 'rails_helper'

RSpec.describe UserFilesController, type: :controller do
  let(:user) { create(:user) }
  let(:user_file) { create(:user_file, user: user) }

  before { session[:user_id] = user.id }

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    let(:file) { fixture_file_upload(Rails.root.join('spec/fixtures/files/test.txt'), 'text/plain') }

    it 'creates a new UserFile' do
      expect {
        post :create, params: { user_file: { file: file } }
      }.to change(UserFile, :count).by(1)
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested user_file' do
      user_file # create the file
      expect {
        delete :destroy, params: { id: user_file.id }
      }.to change(UserFile, :count).by(-1)
    end
  end
end