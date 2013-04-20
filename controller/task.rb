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
      respond("CSRF token error!", 401)
    end
  end

  def index
    redirect r(:all)
  end

  def show(task_id)
    @task = Task[task_id]
    if @task and (@task.is_published or logged_admin?)
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
    @tasks = Task.all.select { |x| x.is_published or logged_admin? }.sort {|a,b| a.price <=> b.price} 
    @title = 'Все таски'
  end

  def new
    @task  = Task.new
    @categories = categories_list()
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
    @categories = categories_list()
    @title = 'Редактировать таск'
    @submit_action = :update
    @csrf_token = get_csrf_token()
    render_view :edit_task
  end


  def save
    redirect r(:all) unless request.post?
    id = request.params['id']

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
      success = 'Таск успешно создан'
      error = 'Невозможно создать таск!'
    end

    task_data = request.subset(:name, :description, :answer_regex, :price)
    task_data[:is_published] = request[:is_published] ? true : false
    category_id = request[:category]

    if !category_id.nil? and !category_id.empty?
        category = Category[category_id]
        if category.nil?
            flash[:error] = 'Нет такой категории'
        end
    end

    begin
      task_data = StringHelper.sanitize_basic(task_data)
      task_data[:category] = category
      task.update(task_data)
      flash[:success] = success
      redirect r(:all)
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

  def categories_list
    Category.all.map {|x| {x.id => x.name} }.reduce {|a, b| a.merge(b)}
  end

  private :categories_list

end
