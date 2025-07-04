class UserFilesController < ApplicationController
  before_action :require_login, except: [:shared, :download, :public_download]
  before_action :set_user_file, only: [:destroy, :download, :share]

  def index
    @user_files = current_user.user_files.order(created_at: :desc)
  end

  def new
    @user_file = current_user.user_files.new
  end

  def create
    uploaded_file = params[:user_file][:file]
    @user_file = current_user.user_files.new(
      name: uploaded_file.original_filename,
      content_type: uploaded_file.content_type,
      size: uploaded_file.size,
      data: uploaded_file.read
    )

    if @user_file.save
      redirect_to dashboard_path, notice: 'File uploaded successfully.'
    else
      render :new
    end
  end

  def destroy
    @user_file.destroy
    redirect_to dashboard_path, notice: 'File deleted successfully.'
  end

  def download
    send_data @user_file.data, filename: @user_file.name, type: @user_file.content_type
  end

  def share
    @user_file.toggle!(:shareable)
    redirect_to dashboard_path
  end

  def shared
    @user_file = UserFile.find_by!(share_token: params[:token])
  end

  def public_download
    file = UserFile.find_by!(share_token: params[:token])

    # Ensure the file is actually shareable before sending
    if file.shareable?
      send_data file.data, filename: file.name, type: file.content_type
    else
      # Or handle this case as you see fit, e.g., redirecting to the login page
      render plain: "This file is not available for sharing.", status: :forbidden
    end
  end

  private

  def set_user_file
    @user_file = current_user.user_files.find(params[:id])
  end

  
end