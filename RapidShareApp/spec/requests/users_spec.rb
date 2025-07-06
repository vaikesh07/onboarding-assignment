require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe "POST /users" do
    it "creates a new user with valid parameters" do
      expect {
        post user_registration_path, params: {
          user: {
            username: 'testuser',
            name: 'Test User',
            email: 'test@example.com',
            password: 'Password123',
            password_confirmation: 'Password123'
          }
        }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(authenticated_root_path)
    end
  end
end