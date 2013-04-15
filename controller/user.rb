# -*- encoding : utf-8 -*-
require 'rack/recaptcha'

class UserController < Controller
  map '/user'

  include Rack::Recaptcha::Helpers

  # admin actions
  before(:make_admin, :remove_admin, :enable, :disable, :all) do
    if !logged_admin?
      flash[:error] = 'Нельзя делать такого!'
      redirect '/'
    end
  end

  # csrf checks
  before_all do
    csrf_protection(:make_admin, :remove_admin, :enable, :disable) do
      respond("CSRF token error!", 401)
    end
  end

  def index
    redirect '/'
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
    redirect '/' if logged_in?
    if request.post?
      if user_login(request.subset('email', 'password'))
        flash[:success] = 'Добро пожаловать'
        redirect MainController.r(:scoreboard)
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
    redirect MainController.r(:scoreboard)
  end

  def register
    redirect '/' if logged_in?
    @recaptcha = recaptcha_tag :challenge
    @user_form = Struct.new(:email, :full_name).new
    if request.post?
      @user_form.email = request[:email]
      @user_form.full_name = request[:full_name]
      if !recaptcha_valid?
        flash[:error] = 'Вы робот!'
      else
        result = User.register(@user_form.email,
                               @user_form.full_name,
                               request[:password],
                               request[:password_confirm])
        if result[:success]
          flash[:success] = 'Аккаунт создан, не забудьте подтвердить регистрацию!'
          redirect r(:login)
        else
          flash[:error] = result[:errors].values.join("<br>")
        end
      end
    end
    @title = 'Регистрация'
  end

  def confirm(user_hash)
    register_confirm = RegisterConfirm.first(:user_hash => user_hash)
    if !register_confirm.nil?
      register_confirm.user.update(:is_disabled => false)
      register_confirm.destroy
      flash[:success] = 'Регистрация пользователя успешно подтверждена!'
      Scoreboard.update_scores
      redirect r(:login)
    end
    redirect '/'
  end

  def make_admin
    redirect MainController.r(:index) unless request.post?
    user_id = request.params['id']
    user = User[user_id]
    redirect_referrer if user.nil? or user.is_admin
    user.update(:is_admin => true)
    flash[:success] = 'Еще один админ! Супер!'
    Scoreboard.update_scores
    redirect_referrer
  end

  def remove_admin
    redirect '/' unless request.post?
    user_id = request.params['id']
    user = User[user_id]
    redirect_referrer if user.nil? or !user.is_admin
    if user.id == @current_user.id
      flash[:error] = 'Не надо лишать себя всех прелестей админства!'
    else
      user.update(:is_admin => false)
      flash[:success] = 'Так ему и надо!'
      Scoreboard.update_scores
    end
    redirect_referrer
  end

  def enable
    redirect '/' unless request.post?
    user_id = request.params['id']
    user = User[user_id]
    redirect_referrer if user.nil? or !user.is_disabled
    user.update(:is_disabled => false)
    flash[:success] = 'Пользователь врублен! Может логиниться!'
    Scoreboard.update_scores
    redirect_referrer
  end

  def disable
    redirect '/' unless request.post?
    user_id = request.params['id']
    user = User[user_id]
    redirect_referrer if user.nil? or user.is_disabled
    if user.id == @current_user.id
      flash[:error] = 'Не-не-не, не надо себя отключать!'
    else
      user.update(:is_disabled => true)
      flash[:success] = 'Так ему и надо!'
      Scoreboard.update_scores
    end
    redirect_referrer
  end

end
