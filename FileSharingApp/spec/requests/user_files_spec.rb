require 'rails_helper'

RSpec.describe "UserFiles", type: :request do
  let(:user) { create(:user, password: 'Password123') }
  let!(:user_file) { create(:user_file, user: user) }

  # Log in the user before running tests for protected actions
  before do
    post login_path, params: { session: { username: user.username, password: 'Password123' } }
    expect(response).to redirect_to(dashboard_path)
  end

  describe "GET /dashboard" do
    it "returns http success" do
      get dashboard_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /user_files/new" do
    it "returns http success" do
      get new_user_file_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /user_files" do
    let(:file) { fixture_file_upload(Rails.root.join('spec/fixtures/files/test.txt'), 'text/plain') }
    
    it "redirects after creating a file" do
      post user_files_path, params: { user_file: { file: file } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /user_files/:id" do
    it "redirects after deleting a file" do
      delete user_file_path(user_file)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "GET /shared/:token" do
    it "returns http success" do
      # Make the file shareable to get a token
      user_file.update(shareable: true)
      get shared_file_path(token: user_file.share_token)
      expect(response).to have_http_status(:success)
    end
  end
end