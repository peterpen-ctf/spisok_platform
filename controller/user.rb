# -*- encoding : utf-8 -*-
require 'rack/recaptcha'

class UserController < Controller
  map '/user'

  include Rack::Recaptcha::Helpers

  # basic actions
  before(:edit, :edit_self, :save) do
    if !logged_in?
      flash[:error] = 'Невозможно!'
      redirect '/'
    end
  end

  # admin actions
  before(:make_admin, :remove_admin, :enable, :disable, :all,
         :new, :delete, :show, :approve, :disapprove) do
    if !logged_admin?
      flash[:error] = 'Нельзя делать такого!'
      redirect '/'
    end
  end

  # csrf checks
  before_all do
    csrf_protection(:make_admin, :remove_admin, :enable, :disable,
                    :save, :delete, :approve, :disapprove) do
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

  def edit_self
    user_id = @current_user.id
    redirect r(:edit, user_id)
  end

  def edit(user_id)
    @user = User[user_id]
    if @user.nil? or (!logged_admin? and @current_user.id.to_s != user_id)
      flash[:error] = 'Нельзя редактировать этого пользователя!'
      redirect '/'
    end
    @csrf_token =  get_csrf_token()
    @title = 'Редактировать пользователя'
    @submit_action = :update
    render_view :edit_user
  end

  def new
    @csrf_token =  get_csrf_token()
    @title = 'Создать пользователя'
    @submit_action = :create
  end

  def save
    redirect r(:all) unless request.post?
    user_id = request.params['id']

    # Update user. Check if user is admin or he wants to edit himself
    if !user_id.nil? and !user_id.empty?

      if !logged_admin? and @current_user.id.to_s != user_id
        flash[:error] = 'Нельзя этого делать!'
        redirect r(:all)
      end

      user = User[user_id]
      if user.nil?
        flash[:error] = 'Неправильный персонаж!'
        redirect r(:all)
      end

      success = 'Пользователь обновлен, ура!'
      error = 'Невозможно обновить пользователя, беда...'

    # Add user. Admins only!
    else
      if !logged_admin?
        flash[:error] = 'Нельзя этого делать!'
        redirect r(:all)
      end

      user = User.new
      success = 'Пользователь успешно создан!'
      error = 'Невозможно создать пользователя...'
    end

    begin
      user_data = {}
#      user_data[:full_name] = StringHelper.escapeHTML(request[:full_name])
#      user_data[:email] = StringHelper.escapeHTML(request[:email])
      user_data[:where_from] = StringHelper.escapeHTML(request[:where_from])
#     user_data[:password] =  PasswordHelper.encrypt_password(user_data[:password].to_s)
      user.update(user_data)
      flash[:success] = success
      redirect(logged_admin? ? r(:all) : '/')
    rescue => e
      Ramaze::Log.error(e)
      flash[:error] = error
      redirect_referrer
    end
  end

  def delete
    redirect r(:all) unless request.post?
    id = request.params['id']

    user = User[id]
    if user.nil?
      flash[:error] = 'Невозможно удалить пользователя: неправильный id'
      redirect_referrer
    end

    begin
      user_score = Scoreboard.find :user_id => user.id
      user_score.destroy
      user.destroy
      flash[:success] = 'Всё окай, пользователь удален'
      redirect r(:all)
    rescue => e
      Ramaze::Log.error(e)
      flash[:error] = 'Проблемы с зависимостями!'
      redirect_referrer
    end
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

  def recover
    if request.post?
      user = User.first(:email => request.params['email'])
      if user.nil?
        flash[:error] = 'Пользователя с данным E-mail не существует'
        redirect UserController.r(:recover)
      else
        if !user.send_recovery
          flash[:error] = 'Что-то пошло не так, попробуйте еще раз'
          redirect UserController.r(:recover)
        end
        flash[:success] = 'Письмо с дальнейшней инструкцией по восстановлению пароля выслано на указанный E-mail'
        redirect MainController.r(:scoreboard)
      end
    end
    @title = 'Восстановить пароль пользователя'
  end

  def new_password(user_hash)
    @user_hash = user_hash
    password_recovery = PasswordRecovery.first(:user_hash => user_hash)
    if password_recovery.nil?
      flash[:error] = 'Ссылка для установки нового пароля уже использована или неверная'
      redirect '/'
    end
    user = password_recovery.user
    if request.post?
      # form data were sent
      user.set_new_password(request[:password],
                            request[:password_confirm])
      if user.valid?
        password_recovery.destroy
        flash[:success] = 'Пароль успешно изменён!'
        redirect UserController.r(:login)
      else
        flash[:error] = user.errors.values.join("<br>")
      end
    end
    @title = 'Установить новый пароль'
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

  # TODO merge enable and disable methods
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

  def approve
    redirect '/' unless request.post?
    user_id = request.params['id']
    user = User[user_id]
    redirect_referrer if user.nil? or user.is_approved
    user.update(:is_approved => true)
    flash[:success] = 'Пользователь может претендовать на приз!'
    redirect_referrer
  end

  def disapprove
    redirect '/' unless request.post?
    user_id = request.params['id']
    user = User[user_id]
    redirect_referrer if user.nil? or !user.is_approved
    user.update(:is_approved => false)
    flash[:success] = 'Пользователь участвует в общем зачете.'
    redirect_referrer
  end

end
