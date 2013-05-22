# -*- encoding : utf-8 -*-
require 'ramaze'
require __DIR__('../../helper/password_helper.rb')

Sequel.migration do
  up do

    # Add users
    users = DB[:users]
    emails = %w/llama alpaca vicugna guanaco bactrian dromedary/
    emails.each do |email|
      users.insert(:email => email + "@ya.ru", :password => PasswordHelper.encrypt_password('123'),
                   :full_name => email + " The Camelidae", :is_disabled => false)
    end

    users[:id=>1] = {:is_admin => true}

    categories = DB[:categories]
    categories.insert({:name => 'reverse', :description => 'esrever'})

    # Add tasks
    tasks = DB[:tasks]
    tasks.insert(:name => 'finder1', :description => 'find the key!', :category_id => 1, :answer_regex => 'ans1', :price => 100)
    tasks.insert(:name => 'finder2', :description => 'find the key again!', :category_id => 1, :answer_regex => 'ans2', :price => 200)

    resources = DB[:resources]
    resources.insert(:name => 'res1', :author_id => 1, :dockerfile => "df1", :is_requested => false, :is_running => false)
    resources.insert(:name => 'res2', :author_id => 2, :dockerfile => "df2", :is_requested => false, :is_running => false)
    resources.insert(:name => 'res3', :author_id => 3, :dockerfile => "df3", :is_requested => true, :is_running => false)
    resources.insert(:name => 'res4', :author_id => 3, :dockerfile => "df1", :is_requested => false, :is_running => true)
    resources.insert(:name => 'res5', :author_id => 3, :dockerfile => "df1", :is_requested => true, :is_running => true)
    resources.insert(:name => 'res6', :author_id => 3, :dockerfile => "df1", :is_requested => false, :is_running => false)

  end

end
