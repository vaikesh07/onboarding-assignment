require 'rails_helper'

RSpec.describe "UserFiles", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/user_files/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/user_files/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/user_files/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/user_files/destroy"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /download" do
    it "returns http success" do
      get "/user_files/download"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /share" do
    it "returns http success" do
      get "/user_files/share"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /shared" do
    it "returns http success" do
      get "/user_files/shared"
      expect(response).to have_http_status(:success)
    end
  end

end
