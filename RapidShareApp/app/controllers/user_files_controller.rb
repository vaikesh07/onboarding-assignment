class UserFilesController < ApplicationController
  before_action :authenticate_user!, except: [:shared, :public_download] # Devise's login check

  def index
    @user_files = current_user.user_files.order(created_at: :desc)
  end

  def new
    @user_file = current_user.user_files.new
  end

  def create
    @user_file = current_user.user_files.new(user_file_params)
    @user_file.name = @user_file.file.file.filename # Get name from uploaded file

    if @user_file.save
      redirect_to dashboard_path, notice: 'File uploaded successfully.'
    else
      render :new
    end
  end

  def destroy
    user_file = current_user.user_files.find(params[:id])
    user_file.destroy
    redirect_to dashboard_path, notice: 'File deleted successfully.'
  end

  def share
    user_file = current_user.user_files.find(params[:id])
    user_file.toggle!(:shareable)
    redirect_to dashboard_path
  end

  def shared
    @user_file = UserFile.find_by!(share_token: params[:token])
  end

  def download
    user_file = current_user.user_files.find(params[:id])
    send_file(
      user_file.file.path,
      filename: user_file.name,
      type: user_file.file.content_type,
      disposition: 'attachment'
    )
  end
  def public_download
    file = UserFile.find_by!(share_token: params[:token])

    # byebug # This will pause your server here

    if file.shareable?
      file_data = file.file.read
      send_data(
        file_data,
        filename: file.name,
        type: file.file.content_type,
        disposition: 'attachment'
      )
    else
      render plain: "This file is not available for sharing.", status: :forbidden
    end
  end

private

  def user_file_params
    params.require(:user_file).permit(:file)
  end
end