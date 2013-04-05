#!/usr/bin/env ruby

class User < Sequel::Model
  one_to_many :submitted_tasks, :class => :Task, :key => :author_id
  one_to_many :submitted_contests, :class => :Contest, :key => :organizer_id
  one_to_many :attempts

  def self.encrypt_password(password, salt)
=begin
    salt + '$' + Digest::SHA2.hexdigest(salt + '---' + password)
=end
    password
  end 

  def self.authenticate(creds)
    username = StringHelper.escapeHTML(creds['username'])
    given_password = creds['password']
    user = User.first(:name => username)
    return false unless user
    user_password = user[:password]
    salt = user_password.split('$')[0]
    if user_password == encrypt_password(given_password, salt)
      return user
    end 
    return false
  end 


end
