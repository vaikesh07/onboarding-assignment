class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(username: params[:session][:username])
    if user&.authenticate(params[:session][:password])
      session[:user_id] = user.id
      redirect_to dashboard_path
    else
      flash.now[:alert] = 'Couldn’t find that user! Please try again'
      render :new
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: 'Logged out successfully.'
  end
end