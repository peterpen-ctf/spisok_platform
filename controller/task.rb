# -*- encoding : utf-8 -*-

class TaskController < Controller
  map '/task'

  # basic actions
  before(:submit) do
    unless logged_in?
      flash[:error] = "Не забудьте залогиниться!"
      redirect r(:all)
    end
  end

  # admin actions
  before(:new, :edit, :save, :delete) do
    unless logged_admin?
      flash[:error] = 'Вам не позволено совершать эти действия, сэр!'
      redirect r(:all)
    end
  end

  # csrf checks
  before_all do
    csrf_protection(:save, :delete) do
      respond("Намутили с CSRF токеном!", 401)
    end
  end

  def index
    redirect r(:all) 
  end

  def show(task_id = nil)
    redirect r(:all) if task_id.nil?
    task_id = task_id.to_i
    @task = Task[task_id]
    if @task
      # task found
      @title = @task.name
    else
      @title = 'Таск не найден...'
    end
    render_view :task_desc
  end

  def all
    @tasks = Task.all
    @title = 'Все таски'
  end


  def new
    @task  = Task.new
    @submit_action = :create
    @csrf_token =  get_csrf_token()
    @title = 'Создать самый новый таск'
    render_view :edit_task
  end

  def edit(id)
    @task = Task[id]
    if @task.nil?
      flash[:error] = 'Невозможно редактировать: неправильный таск!'
      redirect r(:all)
    end
    @title = 'Редактировать таск'
    @submit_action = :update
    @csrf_token =  get_csrf_token()
    render_view :edit_task
  end


  def save
    redirect r(:all) unless request.post?
    id = request.params['id']
    task_data = request.subset(:name, :description, :answer_regex)

    # Update task
    if !id.nil? and !id.empty?
      task = Task[id]
      if task.nil?
        flash[:error] = 'This task is invalid. WTF?'
        redirect r(:all)
      end

      success = 'The task has been updated'
      error = 'The task could not be updated!'

    # New task
    else
      task = Task.new
      success = 'The task has been created'
      error = 'The task could not be created!'
    end

    begin
      task_data = StringHelper.sanitize_basic(task_data)
      task.update(task_data)
      flash[:success] = success
    rescue => e
      Ramaze::Log.error(e)
      flash[:error] = error
    end
    redirect r(:all)
  end


  def submit(id)
    redirect r(:all) unless request.post?
    task = Task[id]
    if task.nil?
      flash[:error] = 'Ошибка: неправильный таск!'
      redirect r(:all)
    end

    last_submit = @current_user.last_submit
    current = Time.now
    @current_user.update(:last_submit => current)


    if !last_submit.nil? and current - last_submit < SUBMIT_WAIT_SECONDS
      flash[:error] = "Слишком частая отправка! Подождите несколько секунд."
      redirect_referrer
    end

    given_answer = request.params['answer'].to_s
    if task.check_answer(given_answer)
      flash[:success] = 'Поздравляем, таск решен!'
    else
      flash[:error] = 'Неудача..'
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

end
