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

  def show(resource_id)
    @resource = Resource[resource_id]
    if @resource
      # resource found
      @title = @resource.name
    else
      @resource = nil
      @title = 'Таск не найден...'
    end
    @is_resource_solved = @current_user.solved_resources.include? @resource
    render_view :resource_desc
  end

  def all
    @resources = Resource.all.select { |x| x.is_published or logged_admin? }.sort {|a,b| a.price <=> b.price}
    @resources.each do |resource|
      # FIXME DAMN SHIT!!!
      solvers_group = Solution.group_and_count(:resource_id).where(:resource_id => resource.id).first
      resource.solvers_num = solvers_group ? solvers_group.values[:count] : 0
    end
    @title = 'Все ресурсы'
  end

  def new
    @resource  = Resource.new
    @categories = categories_list()
    @submit_action = :create
    @csrf_token = get_csrf_token()
    @title = 'Создать самый новый ресурс'
    render_view :edit_resource
  end

  def edit(id)
    @resource = Resource[id]
    if @resource.nil?
      flash[:error] = 'Невозможно редактировать: неправильный ресурс!'
      redirect r(:all)
    end
    @categories = categories_list()
    @title = 'Редактировать ресурс'
    @submit_action = :update
    @csrf_token = get_csrf_token()
    render_view :edit_resource
  end


  def save
    redirect r(:all) unless request.post?
    id = request.params['id']

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
      success = 'Таск успешно создан'
      error = 'Невозможно создать ресурс!'
    end

    resource_data = request.subset(:name, :dockerfile, :is_running, :version)
    resource_data[:is_running] = request[:is_running] ? true : false

    begin
      resource_data = StringHelper.sanitize_basic(resource_data)
      resource.update(resource_data)
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
    resource = Resource[id]
    if resource.nil?
      flash[:error] = 'Ошибка: неправильный ресурс!'
      redirect r(:all)
    end

    given_answer = request.params['answer'].to_s
    result = @current_user.try_submit_answer(resource, given_answer)
    if result[:success]
      flash[:success] = 'Поздравляем, ресурс решен!'
    else
      flash[:error] = result[:errors].join("<br>")
    end
    redirect r(:show, resource.id)
  end


  def delete
    redirect r(:all) unless request.post?
    id = request.params['id']

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

  def categories_list
    Category.all.map {|x| {x.id => x.name} }.reduce {|a, b| a.merge(b)}
  end

  private :categories_list

end
