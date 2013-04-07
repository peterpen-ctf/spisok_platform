require 'ostruct'


class UserController < Controller
  map '/user'

  # admin actions
  before(:make_admin, :remove_admin) do
    if !logged_admin?
      flash[:error] = 'You are not an allowed to do that!'
      redirect r(:all)
    end
  end

  def index
    redirect UserController.r(:all)
  end

  def show(user_id = nil)
    redirect UserController.r(:all) if user_id.nil?
    user_id = user_id.to_i
    @user = User[user_id]
    if @user
      @title = 'User profile'
    else
      flash[:error] = 'No such user...'
    end
    render_view :user_profile
  end

  def all
    @users = User.all
    @title = 'All users'
  end

  def login
    redirect r(:all) if logged_in?
    if request.post?
      if user_login(request.subset('username', 'password'))
        flash[:success] = 'You have been logged in'
        redirect(UserController.r(:all))
      else
        flash[:error] = 'You could not be logged in'
      end 
    end 
    @title = 'Login'
  end 

  def logout
    if logged_in?
      user_logout
      session.clear
      flash[:success] = 'You have been logged out'
    end
    redirect r(:all)
  end

  def register
    redirect r(:all) if logged_in?
    if request.post?
      @user_form = OpenStruct.new(:name => request[:name],
                                  :full_name => request[:full_name],
                                  :password => request[:password],
                                  :password_confirm => request[:password_confirm])
      result = User.register(@user_form.name,
                             @user_form.full_name,
                             @user_form.password,
                             @user_form.password_confirm)
      if result[:success]
        flash[:success] = 'Account created, feel free to login below'
        redirect(UserController.r(:login))
      else
        flash[:error] = result[:errors].values.join("<br>")
      end
    end
    @title = 'Registration'
  end

  def make_admin(user_id)
    user = User[user_id]
    redirect_referrer if user.nil? or user.is_admin
    user.update(:is_admin => true)
    flash[:success] = 'Another superuser! Great!'
    redirect_referrer
  end

  def remove_admin(user_id)
    user = User[user_id]
    redirect_referrer if user.nil? or !user.is_admin
    if user == @current_user
      flash[:error] = 'You cannot unadmin yourself!'
    else
      user.update(:is_admin => false)
      flash[:success] = 'Hahaha! This guy sucks!'
    end
    redirect_referrer
  end
end
