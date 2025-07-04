require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new User and logs them in' do
        expect {
          post :create, params: { user: attributes_for(:user) }
        }.to change(User, :count).by(1)
        expect(session[:user_id]).not_to be_nil
      end
    end

    context 'with invalid params' do
      it 'does not create a new User' do
        expect {
          post :create, params: { user: { username: '' } }
        }.not_to change(User, :count)
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'PATCH #update' do
    before { session[:user_id] = user.id }

    it 'updates the requested user' do
      patch :update, params: { id: user.id, user: { name: 'New Name' } }
      user.reload
      expect(user.name).to eq('New Name')
      expect(response).to redirect_to(profile_path)
    end
  end
end