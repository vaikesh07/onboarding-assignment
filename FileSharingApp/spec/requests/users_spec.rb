require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "GET /signup" do
    it "renders a successful response" do
      get signup_path
      expect(response).to be_successful
    end
  end

  describe "POST /users" do
    context "with valid parameters" do
      let(:valid_attributes) { attributes_for(:user, password: 'Password123') }

      it "creates a new User" do
        expect {
          post users_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it "redirects to the dashboard" do
        post users_path, params: { user: valid_attributes }
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) { attributes_for(:user, username: '') }

      it "does not create a new User" do
        expect {
          post users_path, params: { user: invalid_attributes }
        }.to change(User, :count).by(0)
      end
    end
  end
end