# -*- encoding : utf-8 -*-

class User < Sequel::Model
  one_to_many :submitted_tasks, :class => :Task, :key => :author_id
  one_to_many :submitted_contests, :class => :Contest, :key => :organizer_id
  one_to_many :attempts

  many_to_many  :solved_tasks, :join_table => :solutions,
                :left_key => :user_id, :right_key => :task_id,
                :class => 'Task'

  plugin :validation_helpers

  def password=(password)
    super(PasswordHelper.encrypt_password(password))
  end

  def new_password(password, password_confirm)
    @new_password, @new_password_confirm = password, password_confirm
    self.password = password
  end

  def validate
    validates_format(/^.+\@.+\..+$/, :email, :message => "Неправльный адрес email!")
    validates_unique(:email, :message => "Email '#{email}' уже зарегистрирован!")
    validates_presence(:full_name, :message => "Не указано полное имя!")
    if defined?(@new_password)
      errors.add(:password, 'Не указан пароль') if !@new_password || @new_password.empty?
      errors.add(:password_confirm, 'Пароли не совпадают') unless @new_password == @new_password_confirm
    end
  end

  # self.errors will contain errors if any occured
  def set_new_password(password, password_confirm)
    new_password(password, password_confirm)
    begin
      self.save
    rescue => e
      Ramaze::Log.error(e.message)
    end
  end

  def self.register(email, full_name, password, password_confirm)
    email = StringHelper.escapeHTML(email.strip)
    full_name = StringHelper.escapeHTML(full_name)
    user = User.new(:email => email, :full_name => full_name)
    user.new_password(password, password_confirm)
    begin
      user.save
      user.send_register_confirm
      {:success => true, :user => user}
    rescue => e
      Ramaze::Log.error(e)
      return {:success => false, :errors => user.errors}
    end
  end

  def self.authenticate(creds)
    email = StringHelper.escapeHTML(creds['email'])
    given_password = creds['password']
    user = User.first(:email => email)
    if user and !user.is_disabled
      user_encrypted_password = user.password
      PasswordHelper.check_password?(given_password, user_encrypted_password) ? user : false
    else
      false
    end
  end


  # Damn constants
  SUBMIT_WAIT_SECONDS = 5

  def try_submit_answer(task, given_answer)
    last_submit = self.last_submit
    now = Time.now

    if !last_submit.nil? and now - last_submit < SUBMIT_WAIT_SECONDS
      return {:success => false, :errors => ["Слишком частая отправка! Подождите несколько секунд."]}
    end
    self.update(:last_submit => now)


    # Check if task is already solved by this user.
    if Solution.find(:user_id => self.id, :task_id => task.id)
      return {:success => false, :errors => ["Вы уже решили этот таск!"]}
    end

    # TODO Change to add_attempt or not?
    Attempt.create(:value => given_answer, :user_id => self.id, :task_id => task.id,
                   :time => now, :value => given_answer)

    if task.check_answer(given_answer)
      # Add points, refresh the scoreboard.
      # TODO Race condition! But...one thread at a time????
      add_solved_task(task)
      self.update(:penalty => self.penalty + (now - Time.utc(2013)).floor)
      Scoreboard.update_scores
      return {:success => true}
    else
      return {:success => false, :errors => ["Неправильный флаг!"]}
    end
  end

  def send_mail(options)
    options[:to] = self.email
    EmailHelper.send(options)
  end

  def send_register_confirm
    register_confirm = RegisterConfirm.register(self)
    return false if register_confirm.nil?
    confirm_link = 'http://spisok2013.ppctf.net/user/confirm/%s' % register_confirm.user_hash
    debug_confirm_link = 'http://localhost:7000/user/confirm/%s' % register_confirm.user_hash
    send_mail(:subject => "Подтверждение регистрации на SpisokCTF 2013",
              :template => 'register_confirm.html',
              :vars => {:confirm_link => confirm_link,
                        :debug_confirm_link => debug_confirm_link})
  end

  def send_recovery
    password_recovery = PasswordRecovery.add_recovery(self)
    return false if password_recovery.nil?
    recovery_link = 'http://spisok2013.ppctf.net/user/new_password/%s' % password_recovery.user_hash
    send_mail(:subject => "Восстановление пароля для SpisokCTF 2013",
              :template => 'password_recovery.html',
              :vars => {:recovery_link => recovery_link})
  end

end
