# -*- encoding : utf-8 -*-

# TODO: add ':null => false' to several columns (password, is_admin etc.)
Sequel.migration do
  change do
    create_table :users do
      primary_key :id
      String :email, :unique => true, :null => false
      String :full_name
      TrueClass :is_admin, :default => false
      String :password, :default => '123'
      DateTime :last_submit
    end

    create_table :contests do
      primary_key :id
      String :name, :null => false
      String :full_name
      String :description
      foreign_key :organizer_id, :users
    end

    create_table :categories do
      primary_key :id
      String :name, :null => false
      String :description
    end

    create_table :tasks do
      primary_key :id
      String :name, :null => false
      String :full_name
      String :description
      foreign_key :author_id, :users
      foreign_key :contest_id, :contests
      foreign_key :category_id, :categories

      String :answer_regex
      TrueClass :is_published
      Integer :price
    end

    create_table :solutions do
      foreign_key :user_id, :users
      foreign_key :task_id, :tasks
      primary_key [:user_id, :task_id]
    end

    create_table :attempts do
      primary_key :id
      foreign_key :user_id, :users
      foreign_key :task_id, :tasks
      DateTime :time
      String :value
    end

    create_table :resources do
      primary_key :id
      String :name
      String :dir
    end

    create_table :resources_tasks do
      foreign_key :resource_id, :resources
      foreign_key :task_id, :tasks
      primary_key [:resource_id, :task_id]
    end

    create_table :news do
      primary_key :id
      String :content, :null => false
      DateTime :update_time, :null => false
    end
  end
end
