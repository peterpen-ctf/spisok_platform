# -*- encoding : utf-8 -*-
require 'ramaze'
require __DIR__('../../helper/password_helper.rb')

Sequel.migration do
  up do
    
    users = DB[:users]
    names = %w/llama alpaca vicugna guanaco bactrian dromedary/
    names.each do |name| 
      users.insert(:name => name, :password => PasswordHelper.encrypt_password('123'), :full_name => name.capitalize + " The Camelidae")
    end

    users[:id=>1] = {:is_admin => true}

    tasks = DB[:tasks]
    tasks.insert(:name => 'finder1', :description => 'find the key!')
    tasks.insert(:name => 'finder2', :description => 'find the key again!')

  end

end
