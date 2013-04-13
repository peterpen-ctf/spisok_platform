# -*- encoding : utf-8 -*-

class NewsController < Controller
  map '/news'

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

  def all
    redirect '/'
  end

  def new
    @news  = News.new
    @submit_action = :create
    @csrf_token =  get_csrf_token()
    @title = 'Создать новость'
    render_view :edit_news
  end

  def edit(id)
    @news = News[id]
    if @news.nil?
      flash[:error] = 'Невозможно редактировать: неправильная новость!'
      redirect r(:all)
    end
    @title = 'Редактировать новость'
    @submit_action = :update
    @csrf_token =  get_csrf_token()
    render_view :edit_news
  end


  def save
    redirect r(:all) unless request.post?
    id = request.params['id']
    news_data = request.subset(:content)

    # Update task
    if !id.nil? and !id.empty?
      news = News[id]
      if news.nil?
        flash[:error] = 'Неправильная новость. WTF?'
        redirect r(:all)
      end

      success = 'Новость обновилась, ура!'
      error = 'Невозможно обновить новость, беда...'

      # Add news
    else
      news = News.new
      news.update_time = Time.now
      success = 'Новость успешно создана!'
      error = 'Невозможно создать новость...'
    end

    begin
      news_data = StringHelper.sanitize_basic(news_data)
      news.update(news_data)
      flash[:success] = success
    rescue => e
      Ramaze::Log.error(e)
      flash[:error] = error
    end
    redirect r(:all)
  end


  def delete
    redirect r(:all) unless request.post?
    id = request.params['id']

    news = News[id]
    if news.nil?
      flash[:error] = 'Невозможно удалить новость: неправильный id'
      redirect_referrer
    else
      news.destroy
      flash[:success] = 'Всё окай, новость испарилась'
      redirect r(:all)
    end
  end

end
