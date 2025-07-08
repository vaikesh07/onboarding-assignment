require 'rails_helper'

RSpec.describe "UserFiles", type: :request do
  # Define user and user_file at the top level to be available to all tests
  let(:user) { create(:user) }
  let!(:user_file) { create(:user_file, user: user) }

  context "when user is not logged in" do
    it "redirects from the dashboard to the login page" do
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when user is logged in" do
    before do
      sign_in user # Use the Devise test helper to sign in
    end

    it "shows the dashboard successfully" do
      get dashboard_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("File Dashboard")
    end

    it "creates a new file on upload" do
      # Make sure you have a file at 'spec/fixtures/files/test.txt'
      file_upload = fixture_file_upload(Rails.root.join('spec/fixtures/files/test.txt'), 'text/plain')

      expect {
        post user_files_path, params: { user_file: { file: file_upload } }
      }.to change(UserFile, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end

    it "deletes the database record and the physical file" do
      # Ensure the file exists before the test
      expect(File.exist?(user_file.file.path)).to be true

      # Expect the database count to change by -1
      expect {
        delete user_file_path(user_file)
      }.to change(UserFile, :count).by(-1)

      # Check that the physical file has been deleted from the server
      expect(File.exist?(user_file.file.path)).to be false
    end
  end
end