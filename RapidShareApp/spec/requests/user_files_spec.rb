require 'rails_helper'

RSpec.describe "UserFiles", type: :request do
  let(:user) { create(:user) }

  context "when user is not logged in" do
    it "redirects from the dashboard to the login page" do
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when user is logged in" do
    before do
      sign_in user # This is the Devise test helper!
    end

    it "shows the dashboard successfully" do
      get dashboard_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("File Dashboard")
    end

    it "creates a new file on upload" do
      # Make sure you have a file at 'spec/fixtures/files/test.txt'
      file = fixture_file_upload(Rails.root.join('spec/fixtures/files/test.txt'), 'text/plain')

      expect {
        post user_files_path, params: { user_file: { file: file } }
      }.to change(UserFile, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end
  end
end