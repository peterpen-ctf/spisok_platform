# -*- encoding : utf-8 -*-

class ResourceController < Controller
  map '/resource'

  # basic actions
  before(:submit, :show, :all) do
    unless logged_in?
      flash[:error] = "Не забудьте залогиниться!"
      redirect UserController.r(:login)
    end
  end

  # admin actions
  before(:run, :stop) do
    unless logged_admin?
      flash[:error] = 'Вам не позволено совершать эти действия, сэр!'
      redirect r(:all)
    end
  end

  # admin or owner
  def check_permissions_and_redirect(resource_id)
    if !logged_admin?
      resource = Resource[resource_id]
      if resource and resource.author != @current_user
        flash[:error] = 'Кто Вы такой, сэр?'
        redirect r(:all)
      end
    end
  end
  
  # csrf checks
  before_all do
    csrf_protection(:save, :delete, :run, :stop, :change_linked_tasks) do
      respond("CSRF token error!", 401)
    end
  end

  def index
    redirect r(:all)
  end

  def show(resource_id)
    check_permissions_and_redirect resource_id
    @resource = Resource[resource_id]
    if @resource
      # resource found
      @title = @resource.name
    else
      @resource = nil
      @title = 'Ресурс не найден...'
    end
    render_view :resource_desc
  end

  def all
    @resources = Resource.all.select { |x| @current_user == x.author or logged_admin? }.sort_by do |x|
      sum = 0
      sum -= 4 if x.is_requested ^ x.is_running
      sum -= 2 if x.is_requested
      sum -= 1 if x.is_running
      sum
    end
    @title = 'Все ресурсы'
  end

  def new
    @resource  = Resource.new
    @resource.author = @current_user
    @linked_tasks = []
    @available_tasks = []
    @submit_action = :create
    @csrf_token = get_csrf_token()
    @title = 'Создать самый новый ресурс'
    render_view :edit_resource
  end

  def edit(id)
    check_permissions_and_redirect id
    @resource = Resource[id]
    if @resource.nil?
      flash[:error] = 'Невозможно редактировать: неправильный ресурс!'
      redirect r(:all)
    end
    @linked_tasks = @resource.tasks.map { |t| t.name }
    @available_tasks = Task.all.select { |t| logged_admin? or @current_user == t.author }.map { |t| t.name } - @linked_tasks
    @title = 'Редактировать ресурс'
    @submit_action = :update
    @csrf_token = get_csrf_token()
    render_view :edit_resource
  end


  def save
    redirect r(:all) unless request.post?
    id = request.params['id']
    check_permissions_and_redirect id

    # Update resource
    if !id.nil? and !id.empty?
      resource = Resource[id]
      if resource.nil?
        flash[:error] = 'Неправильный ресурс. WTF?'
        redirect r(:all)
      end

      success = 'Ура, ресурс обновлен!'
      error = 'Невозможно обновить ресурс!'

    # New resource
    else
      resource = Resource.new
      resource.author = @current_user
      success = 'Ресурс успешно создан'
      error = 'Невозможно создать ресурс!'
    end

    resource_data = request.subset(:name, :dockerfile, :is_running, :is_requested, :version)
    resource_data[:is_running] = request[:is_running] ? true : false
    resource_data[:is_requested] = request[:is_requested] ? true : false

    begin
      #resource_data = StringHelper.sanitize_basic(resource_data)
      resource.update(resource_data)
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
    check_permissions_and_redirect id

    resource = Resource[id]
    if resource.nil?
      flash[:error] = 'Невозможно удалить ресурс: неправильный id'
      redirect_referrer
    else
      resource.destroy
      flash[:success] = 'Всё окай, ресурс в топке'
      redirect r(:all)
    end
  end

  def run
    redirect r(:all) unless request.post?
    id = request.params['id']

    resource = Resource[id]
    if resource.nil?
      flash[:error] = 'Невозможно запустить ресурс: неправильный id'
      redirect_referrer
    #elsif resource.version != request.params['version']
    #  flash[:error] = 'Resource version is obsolete'
    #  redirect_referrer
    else
      Ramaze::Log.error("running #{id}...")
      tf = Tempfile.new(["platform", ".docker"])
      
      Ramaze::Log.error(tf.path)
      tf.write resource.dockerfile
      tf.close
      image_msg = `docker build < #{tf.path}`
      Ramaze::Log.error image_msg
      image_id = image_msg.split[-1].chomp
      Ramaze::Log.error "Image id: #{image_id}"
      container_id = `docker run -d -p 12345 #{image_id}`.chomp
      Ramaze::Log.error "Container id: #{container_id}"
      host_port = `docker port #{container_id} 12345`
      Ramaze::Log.error "Container port: #{host_port}"
      #Ramaze::Log.error msg
      resource.is_running = true
      resource.container_id = container_id
      resource.host_port = host_port
      resource.save
      flash[:success] = 'Всё окай, ресурс запущен'
      redirect_referrer
    end
  end

  def stop
    redirect r(:all) unless request.post?
    id = request.params['id']

    resource = Resource[id]
    if resource.nil?
      flash[:error] = 'Невозможно остановить ресурс: неправильный id'
      redirect_referrer
    else
      `docker stop #{resource.container_id}`
      Ramaze::Log.error("#{id} остановлен")
      resource.is_running = false
      resource.container_id = nil
      resource.host_port = nil
      resource.save
      flash[:success] = 'Всё окай, ресурс остановлен'
      redirect r(:all)
    end
  end

  def change_linked_tasks
    id = request.params['id']
    check_permissions_and_redirect id
    resource = Resource[id]
    tasks = []
    access_violated = false
    request.params['tasks'].each do |task_name|
      task = Task.first(:name => task_name)
      if task.author != @current_user and !logged_admin?
        access_violated = true
        break
      else
        tasks << task
      end
    end

    if access_violated
      flash[:error] = 'Кто-то захотел связать не свою задачу...'
      redirect_referrer
    else
      flash[:success] = 'Связанные задачи обновлены'
      resource.remove_all_tasks
      tasks.each { |t| resource.add_task t }
      redirect_referrer
    end

  end

end
