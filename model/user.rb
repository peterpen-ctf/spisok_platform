#!/usr/bin/env ruby


class User < Sequel::Model
  one_to_many :submitted_tasks, :class => :Task, :key => :author_id
  one_to_many :submitted_contests, :class => :Contest, :key => :organizer_id
  one_to_many :attempts

  def self.authenticate(creds)
    username = StringHelper.escapeHTML(creds['username'])
    user = User.first(:name => username)
    return false unless user
    given_password = creds['password']
    user_encrypted_password = user.password
    PasswordHelper.check_password?(given_password, user_encrypted_password) ? user : false
  end

end