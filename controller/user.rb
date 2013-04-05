
class UserController < Controller
  map '/user'

  def index
    redirect UserController.r(:all)
  end


  def show(user_id)
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

end
