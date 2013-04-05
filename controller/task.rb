
class TaskController < Controller
  map '/task'

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
      @title = 'No task found...'
    end
    render_view :task_desc
  end

  def all
    @tasks = Task.all
    @title = 'All tasks'
  end


  def new
    if !logged_in? or !user.is_admin
      flash[:error] = 'You are not an admin!'
    else
      flash[:success] = 'OK'
    end
    redirect r(:all)
  end

end
