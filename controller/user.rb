require 'ostruct'


class UserController < Controller
  map '/user'

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
    user_logout
    session.clear
    flash[:success] = 'You have been logged out'
    redirect(UserController.r(:all))
  end

  def register
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
    @title = 'Registeration'
  end

end
