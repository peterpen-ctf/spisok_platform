# -*- encoding : utf-8 -*-

class ContestController < Controller
  map '/contest'

  # basic actions
  before(:show, :all) do
    unless logged_in?
      flash[:error] = "Не забудьте залогиниться!"
      redirect UserController.r(:login)
    end
  end

  # admin or owner
  def check_permissions_and_redirect(contest_id)
    if !logged_admin?
      contest = Contest[contest_id]
      if contest and contest.organizer != @current_user
        flash[:error] = 'Контест открыт в режиме просмотра. Для редактирования необходимо зайти под аккаунтом с соответствующими правами.'
        redirect r(:show, contest_id)
      end
    end
  end

  # csrf checks
  before_all do
    csrf_protection(:save, :delete) do
      respond("CSRF token error!", 401)
    end
  end

  def index
    redirect r(:all)
  end

  def all
    @contests = Contest.all
    @title = 'Все контесты'
  end

  def show(contest_id)
    @contest = Contest[contest_id]
    if @contest
      @title = 'Параметры контеста'
    else
      flash[:error] = 'Нет такого...'
    end
    render_view :contest_profile
  end

  def new
    @contest = Contest.new
    @contest.organizer = @current_user
    @submit_action = :create
    @csrf_token = get_csrf_token()
    @title = 'Создать новый контест'
    render_view :edit_contest
  end

  def edit(id)
    @contest = Contest[id]
    if @contest.nil?
      flash[:error] = 'Невозможно редактировать: неправильный контест!'
      redirect r(:all)
    end

    check_permissions_and_redirect id
    @title = 'Редактировать контест'
    @submit_action = :update
    @csrf_token = get_csrf_token()
    render_view :edit_contest
  end


  def save
    redirect r(:all) unless request.post?
    id = request.params['id']
    check_permissions_and_redirect id

    # Update contest
    if !id.nil? and !id.empty?
      contest = Contest[id]
      if contest.nil?
        flash[:error] = 'Неправильный контест. WTF?'
        redirect r(:all)
      end

      success = 'Ура, контест обновлен!'
      error = 'Невозможно обновить контест!'

    # New contest
    else
      contest = Contest.new
      contest.organizer = @current_user
      success = 'Контест успешно создан'
      error = 'Невозможно создать контест!'
    end

    contest_data = request.subset(:name, :full_name, :description)
    contest_data[:is_approved] = request[:is_approved] ? true : false
    contest_data[:is_published] = request[:is_published] ? true : false

    begin
      contest_data = StringHelper.sanitize_basic(contest_data)
      contest.update(contest_data)
      flash[:success] = success
      redirect r(:all)
    rescue => e
      Ramaze::Log.error(e)
      flash[:error] = error
      redirect_referrer
    end
  end

  def delete
    redirect r(:all) unless request.post?
    id = request.params['id']

    contest = Contest[id]
    if contest.nil?
      flash[:error] = 'Невозможно удалить контест: неправильный id'
      redirect_referrer
    else
      contest.destroy
      flash[:success] = 'Всё окай, контест был удален'
      redirect r(:all)
    end
  end

end
