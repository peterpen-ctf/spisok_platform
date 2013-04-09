# -*- encoding : utf-8 -*-

require 'net/ldap'
require 'timeout'


class ActiveDirectoryUser
  attr_reader :name, :password, :full_name

  def initialize(entry, password)
    @name = entry.samaccountname.first
    @full_name = entry.displayname.first
    @password = password
  end

  # A factory method: if a user is authenticated successfully,
  # returns a new instance of the ActiveDirectoryUser.
  def self.authenticate(username, password)
    return nil if username.empty? or password.empty? or
                  username.nil? or password.nil?
    ldap = Net::LDAP.new(:host => AD_HOST,
                         :port => AD_PORT,
                         :base => AD_BASE,
                         :auth => {:username => "#{username}@#{AD_DOMAIN}",
                                   :password => password,
                                   :method => :simple})
    ldap.encryption(:simple_tls) if AD_USE_SSL
    user = nil
    begin
      timeout(AD_TIMEOUT) do
        return nil unless ldap.bind
        user = ldap.search(:filter => "sAMAccountName=#{username}").first
      end
    # Now handle all LDAP and network exceptions
    rescue Timeout::Error => e
      Ramaze::Log.error("LDAP error, user '#{username}': Timeout!")
    rescue Net::LDAP::LdapError, SystemCallError => e
      Ramaze::Log.error(e)
    end
    user ? self.new(user, password) : nil
  end
end


class User < Sequel::Model
  one_to_many :submitted_tasks, :class => :Task, :key => :author_id
  one_to_many :submitted_contests, :class => :Contest, :key => :organizer_id
  one_to_many :attempts

  plugin :validation_helpers

  def password=(password)
    super(PasswordHelper.encrypt_password(password))
  end

  def new_password(password, password_confirm)
    @new_password, @new_password_confirm = password, password_confirm
    self.password = password
  end

  def validate
    super
    validates_format(/^.+\@.+\..+$/, :email, :message => "E-mail address is not correct")
    validates_unique(:email, :message => "E-mail '#{email}' is already registered")
    validates_presence(:full_name, :message => "Full name is not present")
    if defined?(@new_password)
      errors.add(:password, 'Password is not present') if !@new_password || @new_password.empty?
      errors.add(:password_confirm, 'Passwords do not match') unless @new_password == @new_password_confirm
    end
  end

  def self.register(email, full_name, password, password_confirm)
    user = User.new(:email => email, :full_name => full_name)
    user.new_password(password, password_confirm)
    begin
      user.save
    rescue => e
      Ramaze::Log.error(e)
      return {:success => false, :errors => user.errors}
    end
    {:success => true, :user => User.first(:email => email)}
  end

  def self.authenticate(creds)
    email = StringHelper.escapeHTML(creds['email'])
    given_password = creds['password']
    user = User.first(:email => email)
    if user
      user_encrypted_password = user.password
      PasswordHelper.check_password?(given_password, user_encrypted_password) ? user : false
    else
      Ramaze::Log.debug("Try to login via AD")
      ad_user = ActiveDirectoryUser.authenticate(email, given_password)
      return false unless ad_user
      Ramaze::Log.debug("Successfully logged in via AD")
      # TODO: Save the given plaintext AD password somewhere :)
      Ramaze::Log.debug("Try to register an AD user in our local database")
      result = self.register(ad_user.name,
                             ad_user.full_name,
                             ad_user.password,
                             ad_user.password)  # password confirmation
      if result[:success]
        Ramaze::Log.debug("AD user '#{ad_user.name}' registered successfully")
        user = result[:user]
      else
        false
      end
    end
  end

end
