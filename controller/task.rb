
class TaskController < Controller
  map '/task'

  # basic
  before(:submit) do
    unless logged_in?
      flash[:error] = "Hey, don't forget to login!"
      redirect r(:all)
    end
  end

  # admin actions
  before(:new, :edit, :save, :delete) do
    unless logged_admin?
      flash[:error] = 'You are not an allowed to do that!'
      redirect r(:all)
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
      @title = 'No task found...'
    end
    render_view :task_desc
  end

  def all
    @tasks = Task.all
    @title = 'All tasks'
  end


  def new
    @task  = Task.new
    @submit_label = 'Create task'
    render_view :edit_task
  end

  def edit(id)
    @task = Task[id]
    if @task.nil?
      flash[:error] = 'Cannot edit: invalid task!'
      redirect r(:all)
    end
    @title = 'Edit task'
    @submit_label = 'Update task'
    render_view :edit_task
  end

  def delete(id)
    task = Task[id]
    if task.nil?
      flash[:error] = 'Cannot delete: invalid task!'
    else
      task.destroy
    end
    redirect r(:all)
  end

  def save
    redirect r(:all) unless request.post?
    task_data = request.subset(:name, :description, :answer_regex)
    id = request.params['id']

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
      flash[:error] = 'Cannot submit: invalid task!'
      redirect r(:all)
    end
    given_answer = request.params['answer'].to_s
    if task.check_answer(given_answer)
      flash[:success] = 'Congrats!'
    else
      flash[:error] = 'Fail..'
    end
    redirect r(:show, task.id)
  end

end
