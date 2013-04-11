# -*- encoding : utf-8 -*-
require 'ramaze'
require __DIR__('../../helper/password_helper.rb')

Sequel.migration do
  up do
    
    users = DB[:users]
    emails = %w/llama alpaca vicugna guanaco bactrian dromedary/
    emails.each do |email| 
      users.insert(:email => email + "@ya.ru", :password => PasswordHelper.encrypt_password('123'),
                   :full_name => email + " The Camelidae")
    end

    users[:id=>1] = {:is_admin => true}

    tasks = DB[:tasks]
    tasks.insert(:name => 'finder1', :description => 'find the key!', :answer_regex => 'ans1')
    tasks.insert(:name => 'finder2', :description => 'find the key again!', :answer_regex => 'ans2')

  end

end
