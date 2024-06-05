class UsersController < ApplicationController
  before_action :authenticate_user, only: [:update, :show]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      respond_to do |format|
        format.json { render json: { user: @user.to_hash.merge(token: generate_token(@user)) }, status: :created }
        format.html { redirect_to login_users_path, notice: 'User created successfully. Please log in.' }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
        format.html do
          flash.now[:error] = @user.errors.full_messages.to_sentence
          render :new
        end
      end
    end
  end

  def login_form
    render :login_form
  end

  def login
    user = User.find_by_email(params[:email])
    if user && BCrypt::Password.new(user.password_digest) == params[:password]
      Rails.logger.debug "User authenticated successfully: #{user.id}"
      respond_to do |format|
        format.json { render json: { user: user.to_hash.merge(token: generate_token(user)) }, status: :ok }
        format.html do
          session[:user_id] = user.id
          Rails.logger.debug "Session user_id set: #{session[:user_id]}"
          redirect_to root_path, notice: 'Logged in successfully'
        end
      end
    else
      Rails.logger.debug "User authentication failed"
      respond_to do |format|
        format.json { render json: { errors: ['Invalid email or password'] }, status: :unprocessable_entity }
        format.html do
          flash.now[:error] = 'Invalid email or password'
          render :login_form
        end
      end
    end
  end

  def logout
    session[:user_id] = nil
    redirect_to root_path, notice: 'Logged out successfully'
  end

  def show
    user = User.find_by_username(params[:username])
    if user.nil?
      respond_to do |format|
        format.html { redirect_to root_path, alert: 'User not found' }
        format.json { render json: { errors: ['User not found'] }, status: :not_found }
      end
      return
    end

    @profile = Profile.new(user.to_hash.merge(following: current_user&.following?(user)))
    @articles = user.articles

    respond_to do |format|
      format.html
      format.json { render json: { profile: @profile.to_hash } }
    end
  end

  def update
    if current_user.update(user_params)
      render json: { user: current_user.to_hash }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :bio, :image)
  end

  def generate_token(user)
    JWT.encode({ user_id: user.id }, Rails.application.secret_key_base)
  end
end
