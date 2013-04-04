
class UserController < Controller
  map '/user'

  def index(user_id = nil)
    redirect UserController.r(:all) if user_id.nil?
    user_id = user_id.to_i
    @user = User[user_id]
    if @user
      @title = 'User profile'
    else
      @title = 'No such user...'
    end
    render_view :user_profile
  end


  def all
    @users = User.all
    @title = 'All users'
  end


end
