require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user, password: 'Password123') }

  describe 'POST #create' do
    context 'with valid credentials' do
      it 'logs the user in and redirects to dashboard' do
        post :create, params: { session: { username: user.username, password: 'Password123' } }
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(dashboard_path)
      end
    end

    context 'with invalid credentials' do
      it 'does not log the user in and re-renders the login form' do
        post :create, params: { session: { username: user.username, password: 'wrongpassword' } }
        expect(session[:user_id]).to be_nil
        expect(flash.now[:alert]).to be_present
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'logs the user out' do
      session[:user_id] = user.id
      delete :destroy
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(login_path)
    end
  end
end