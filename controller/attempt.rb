# -*- encoding : utf-8 -*-

class AttemptController < Controller
  map '/attempt'

  before_all do
    if !logged_admin?
      flash[:error] = 'Нельзя делать такого!'
      redirect '/'
    end
  end

  def index
    @page = request[:page].to_i
    n = request[:limit].to_i
    if n <= 0 then n = 100 end

    @title = "Последние " + n.to_s + " попыток"
    @attempts = Attempt.all.sort{|a,b| b.time <=> a.time}[@page * n... (@page+1) * n] || []
    @limit = n
    render_view :all
  end

  def by_user(user_id)
    user = User[user_id]
    if user.nil?
      flash[:error] = 'Нет такого юзера'
      redirect '/'
    end
    @page = request[:page].to_i
    n = request[:limit].to_i
    if n <= 0 then n = 100 end

    @attempts = Attempt.all.select{|x| x.user == user}.sort{|a,b| b.time <=> a.time}[@page * n... (@page+1) * n] || []
    @title = "Последние попытки " + user.full_name
    @limit = n
    render_view :all
  end

  def by_task(task_id)
    task = Task[task_id]
    if task.nil?
      flash[:error] = 'Нет такого таска'
      redirect '/'
    end
    @page = request[:page].to_i
    n = request[:limit].to_i
    if n <= 0 then n = 100 end

    @attempts = Attempt.all.select{|x| x.task == task}.sort{|a,b| b.time <=> a.time}[@page * n... (@page+1) * n] || []
    @title = "Последние попытки по " + task.name
    @limit = n
    render_view :all
  end

end
