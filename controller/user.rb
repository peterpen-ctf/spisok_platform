# -*- encoding : utf-8 -*-

class UserController < Controller
  map '/user'

  # admin actions
  before(:make_admin, :remove_admin, :enable, :disable) do
    if !logged_admin?
      flash[:error] = 'Нельзя делать такого!'
      redirect r(:all)
    end
  end

  def index
    redirect r(:all)
  end

  def show(user_id)
    @user = User[user_id]
    @csrf_token = get_csrf_token()
    if @user
      @title = 'Профиль участника'
    else
      flash[:error] = 'Нет такого...'
    end
    render_view :user_profile
  end

  def all
    @users = User.all
    @title = 'Участники'
  end

  def login
    redirect r(:all) if logged_in?
    if request.post?
      if user_login(request.subset('email', 'password'))
        flash[:success] = 'Добро пожаловать'
        redirect r(:all)
      else
        flash[:error] = 'Неверные E-mail/Пароль или пользователь еще не активирован'
        @user = Struct.new(:email, :password).new
        @user.email = request.params['email']
      end
    end
    @title = 'Вход'
  end 

  def logout
    if logged_in?
      user_logout
      session.clear
      flash[:success] = 'Пока-пока'
    end
    redirect r(:all)
  end

  def register
    redirect r(:all) if logged_in?
    if request.post?
      @user_form = Struct.new(:email, :full_name, :password, :password_confirm).new
      @user_form.email = request[:email]
      @user_form.full_name = request[:full_name]
      @user_form.password = request[:password]
      @user_form.password_confirm = request[:password_confirm]
      result = User.register(@user_form.email,
                             @user_form.full_name,
                             @user_form.password,
                             @user_form.password_confirm)
      if result[:success]
        flash[:success] = 'Аккаунт создан, теперь можно зайти'
        redirect r(:login)
      else
        flash[:error] = result[:errors].values.join("<br>")
        # clear password inputs
        @user_form.password = ''
        @user_form.password_confirm = ''
      end
    end
    @title = 'Регистрация'
  end

  def confirm(user_hash)
    register_confirm = RegisterConfirm.first(:user_hash => user_hash)
    if !register_confirm.nil?
      register_confirm.user.update(:is_disabled => false)
      register_confirm.destroy
      Scoreboard.update_scores
      flash[:success] = 'Регистрация пользователя успешно подтверждена!'
      redirect r(:login)
    end
    redirect r(:all)
  end

  def make_admin
    redirect r(:all) unless request.post?
    user_id = request.params['id']
    user = User[user_id]
    redirect_referrer if user.nil? or user.is_admin
    user.update(:is_admin => true)
    flash[:success] = 'Еще один админ! Супер!'
    redirect_referrer
  end

  def remove_admin
    redirect r(:all) unless request.post?
    user_id = request.params['id']
    user = User[user_id]
    redirect_referrer if user.nil? or !user.is_admin
    if user.id == @current_user.id
      flash[:error] = 'Не надо лишать себя всех прелестей админства!'
    else
      user.update(:is_admin => false)
      flash[:success] = 'Так ему и надо!'
    end
    redirect_referrer
  end

  def enable
    redirect r(:all) unless request.post?
    user_id = request.params['id']
    user = User[user_id]
    redirect_referrer if user.nil? or !user.is_disabled
    user.update(:is_disabled => false)
    flash[:success] = 'Пользователь врублен! Может логиниться!'
    redirect_referrer
  end

  def disable
    redirect r(:all) unless request.post?
    user_id = request.params['id']
    user = User[user_id]
    redirect_referrer if user.nil? or user.is_disabled
    if user.id == @current_user.id
      flash[:error] = 'Не-не-не, не надо себя отключать!'
    else
      user.update(:is_disabled => true)
      flash[:success] = 'Так ему и надо!'
    end
    redirect_referrer
  end

end
