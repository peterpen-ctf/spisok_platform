
class TaskController < Controller
  map '/task'

  def initialize
    @current_user = user
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
      redirect r(:all)
    end

    if request.post?
      task_name = request[:task_name]
      task_desc = request[:task_desc]

      task = Task.new(:name => task_name, :description => task_desc)
      if task.valid?
        task.save
        flash[:success] = 'OK'
        redirect r(:all)
      else
        flash[:error] = 'Invalid data!'
        render_view :new_task
      end
    end
    render_view :new_task
  end

end
