require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, password: 'Password123') }

  describe "POST /login" do
    it "logs the user in and redirects to the dashboard" do
      post login_path, params: { session: { username: user.username, password: 'Password123' } }
      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response.body).to include('File Dashboard')
    end
  end

  describe "DELETE /logout" do
    it "logs the user out and redirects to the login page" do
      # First, log in
      post login_path, params: { session: { username: user.username, password: 'Password123' } }
      
      # Then, log out
      delete logout_path
      expect(response).to redirect_to(login_path)
    end
  end
end