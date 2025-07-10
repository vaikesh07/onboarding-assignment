require 'rails_helper'

RSpec.describe UserFilesController, type: :controller do
  let(:user) { create(:user) }
  let(:user_file) { create(:user_file, user: user) }

  # Log in a user before running the tests
  before do
    sign_in user
  end

  # Uncomment these tests if you want to test the index and new actions and it will require you to upgrade your rspec version to 4.0.0 or above, that is one of the constraint in our assignment.
  # describe "GET #index" do
  #   it "returns http success" do
  #     get :index
  #     expect(response).to have_http_status(:success)
  #   end
  # end

  # describe "GET #new" do
  #   it "returns http success" do
  #     get :new
  #     expect(response).to have_http_status(:success)
  #   end
  # end

  describe "POST #create" do
    let(:file_upload) { fixture_file_upload(Rails.root.join('spec/fixtures/files/test.txt'), 'text/plain') }

    it "redirects after creating a file" do
      post :create, params: { user_file: { file: file_upload } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE #destroy" do
    it "redirects after deleting a file" do
      # We must pass the id of the file to be deleted
      delete :destroy, params: { id: user_file.id }
      expect(response).to have_http_status(:redirect)
    end
  end
end