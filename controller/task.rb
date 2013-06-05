# -*- encoding : utf-8 -*-

class TaskController < Controller
  map '/task'

  # basic actions
  before(:submit, :show, :all) do
    unless logged_in?
      flash[:error] = "Не забудьте залогиниться!"
      redirect UserController.r(:login)
    end
  end

  # admin or owner
  def check_permissions_and_redirect(task_id)
    if !logged_admin?
      task = Task[task_id]
      if task and task.author != @current_user
        flash[:error] = 'Кто Вы такой, сэр?'
        redirect r(:all)
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


  def show(task_id)
    @task = Task[task_id]
    if @task and (@task.is_published or logged_admin? or @task.author.id == @current_user.id)
      # task found
      @title = @task.name
    else
      @task = nil
      @title = 'Таск не найден...'
    end
    @is_task_solved = @current_user.solved_tasks.include? @task
    render_view :task_desc
  end


  def all
    @tasks = Task.all.select do |task|
      logged_admin? or
      (task.is_published and task.contest.is_published) or
      task.author == @current_user
    end.sort_by do |task|
      task.author == @current_user ? 0 : -task.price
    end
    
    @contests = make_select_list(Contest) do |contest|
      logged_admin? or
      (contest.is_published and
        @tasks.select do |task|
          task.contest == contest
        end.length > 0) or
      contest.organizer == @current_user
    end

    @is_admin = logged_admin?
    @title = 'Все таски'
  end


  def new
    @task  = Task.new
    @task.author = @current_user
    @contests = make_select_list(Contest) do |contest|
      logged_admin? or contest.organizer == @current_user
    end
    @categories = make_select_list(Category)
    @submit_action = :create
    @csrf_token = get_csrf_token()
    @title = 'Создать самый новый таск'
    render_view :edit_task
  end


  def edit(id)
    @task = Task[id]
    if @task.nil?
      flash[:error] = 'Невозможно редактировать: неправильный таск!'
      redirect r(:all)
    end

    check_permissions_and_redirect id
    @contests = make_select_list(Contest) do |contest|
      logged_admin? or contest.organizer == @current_user
    end
    @categories = make_select_list(Category)
    @title = 'Редактировать таск'
    @submit_action = :update
    @csrf_token = get_csrf_token()
    render_view :edit_task
  end


  def save
    redirect r(:all) unless request.post?
    id = request.params['id']
    check_permissions_and_redirect id

    # Update task
    if !id.nil? and !id.empty?
      task = Task[id]
      if task.nil?
        flash[:error] = 'Неправильный таск. WTF?'
        redirect r(:all)
      end

      success = 'Ура, таск обновлен!'
      error = 'Невозможно обновить таск!'

    # New task
    else
      task = Task.new
      task.author = @current_user
      success = 'Таск успешно создан'
      error = 'Невозможно создать таск!'
    end

    task_data = request.subset(:name, :description, :answer_regex, :price)
    task_data[:is_published] = request[:is_published] ? true : false
    
    begin
      category_id = request[:category]
      category = get_entity_by_id(category_id, Category, 'Нет такой категории')
      contest_id = request[:contest]
      contest = get_entity_by_id(contest_id, Contest, 'Неверно выбран контест') do |contest|
        logged_admin? or contest.organizer == @current_user
      end
    
      task_data = StringHelper.sanitize_basic(task_data)
      task_data[:category] = category
      task_data[:contest] = contest
      task.update(task_data)
      flash[:success] = success
      redirect r(:all)
    rescue UnknownRecordException => e
      Ramaze::Log.error(e)
      flash[:error] = (e.message.nil? or e.message.empty?) ? error : e.message
      redirect_referrer
    rescue => e
      Ramaze::Log.error(e)
      flash[:error] = error
      redirect_referrer
    end
  end


  def submit(id)
    redirect r(:all) unless request.post?
    task = Task[id]
    if task.nil?
      flash[:error] = 'Ошибка: неправильный таск!'
      redirect r(:all)
    end

    given_answer = request.params['answer'].to_s
    result = @current_user.try_submit_answer(task, given_answer)
    if result[:success]
      flash[:success] = 'Поздравляем, таск решен!'
    else
      flash[:error] = result[:errors].join("<br>")
    end
    redirect r(:show, task.id)
  end


  def delete
    redirect r(:all) unless request.post?
    id = request.params['id']

    task = Task[id]
    if task.nil?
      flash[:error] = 'Невозможно удалить таск: неправильный id'
      redirect_referrer
    else
      task.destroy
      flash[:success] = 'Всё окай, таск в топке'
      redirect r(:all)
    end
  end
  
  # Returns a valid hash for html form select element, combined of all entities
  # for the given +model+, where only id and name attributes are taken as
  # values and keys correspondingly. Provide block returning boolean if you
  # need to select only specific entities.
  #
  # * *Args*    :
  #   - +model+ -> ORM interface for specific entities'
  #   - +&cond+ -> block {|x| boolean}, filtering entities upon iterations
  # * *Returns* :
  #   - hash of {entity.id => entity.name}
  #
  def make_select_list(model, &cond)
=begin
    cond = lambda {|a| true} unless block_given?  # always true functor, if no block was given
    # Entities filtered by cond, followed by filtration by (id, name)
    # In reduce: a - accumulator, b - element
    model.all.map {|x| (cond.call(x) ? {x.id => x.name} : {}) }.reduce {|a, b| a.merge(b)}
=end
    
    cond ||= proc { true } # cond defaults to proc { true }
    # Entities filtered by cond, followed by filtration by (id, name)
    model.all.map do |x|
      cond.(x) ? {x.id => x.name} : {}
    end.reduce Hash.new do |memo, e| memo.merge(e) end
  end

  private :make_select_list
end
