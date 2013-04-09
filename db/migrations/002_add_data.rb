require 'ramaze'
require __DIR__('../../helper/password_helper.rb')

Sequel.migration do
  up do
    
    users = DB[:users]
    emails = %w/llama alpaca vicugna guanaco bactrian dromedary/
    emails.each do |email| 
      users.insert(:email => email, :password => PasswordHelper.encrypt_password('123'), :full_name => email + " The Camelidae")
    end

    users[:id=>1] = {:is_admin => true}

    tasks = DB[:tasks]
    tasks.insert(:name => 'finder1', :description => 'find the key!')
    tasks.insert(:name => 'finder2', :description => 'find the key again!')

  end

end
