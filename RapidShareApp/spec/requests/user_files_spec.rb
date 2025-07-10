require 'rails_helper'

RSpec.describe "UserFiles", type: :request do
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
      sign_in user
    end

    it "shows the dashboard successfully" do
      get dashboard_path
      expect(response).to have_http_status(:success)
    end

    it "creates a new file on upload" do
      file_upload = fixture_file_upload(Rails.root.join('spec/fixtures/files/test.txt'), 'text/plain')
      expect {
        post user_files_path, params: { user_file: { file: file_upload } }
      }.to change(UserFile, :count).by(1)
      expect(response).to redirect_to(dashboard_path)
    end

    # CORRECTED TEST FOR SUCCESSFUL DELETION
    it "deletes the database record and the physical file" do
      # Store the file path before the object is destroyed
      file_path = user_file.file.path
      expect(File.exist?(file_path)).to be true

      expect {
        delete user_file_path(user_file)
      }.to change(UserFile, :count).by(-1)

      expect(File.exist?(file_path)).to be false
    end

    # CORRECTED TEST FOR FAILED DELETION
    it "does not delete the database record if the physical file deletion fails" do
      # Simulate a file system error
      allow_any_instance_of(FileUploader).to receive(:remove!).and_raise(StandardError, "File System Error")

      # Expect that the destroy action does NOT change the UserFile count
      # because the transaction will be rolled back.
      expect {
        delete user_file_path(user_file)
      }.to_not change(UserFile, :count)

      # The user should be redirected back to the dashboard
      expect(response).to redirect_to(dashboard_path)
    end
  end
end