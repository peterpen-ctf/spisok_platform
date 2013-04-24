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
    n = request[:limit].to_i
    if n <= 0 then n = 100 end
    @attempts = Attempt.all.sort{|a,b| b.time <=> a.time}[0...n]
    @title = "Последние " + n.to_s + " попыток"
    render_view :all
  end

  def by_user(user_id)
    user = User[user_id]
    if user.nil?
      flash[:error] = 'Нет такого юзера'
      redirect '/'
    end
    @attempts = Attempt.all.select{|x| x.user == user}.sort{|a,b| b.time <=> a.time}
    @title = "Последние попытки " + user.full_name
    render_view :all
  end

  def by_task(task_id)
    task = Task[task_id]
    if task.nil?
      flash[:error] = 'Нет такого таска'
      redirect '/'
    end
    @attempts = Attempt.all.select{|x| x.task == task}.sort{|a,b| b.time <=> a.time}
    @title = "Последние попытки по " + task.name
    render_view :all
  end

end
