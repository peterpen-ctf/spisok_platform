
class TaskController < Controller
  map '/task'

  def index
    redirect TaskController.r(:all) 
  end

  def show(task_id = nil)
    redirect TaskController.r(:all) if task_id.nil?
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

end
