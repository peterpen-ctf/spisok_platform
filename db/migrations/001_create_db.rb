# -*- encoding : utf-8 -*-

# TODO: add ':null => false' to several columns (password, is_admin etc.)
Sequel.migration do
  change do
    create_table :users do
      primary_key :id
      String :email, :unique => true, :null => false
      String :full_name
      String :password, :null => false
      String :where_from
      TrueClass :is_admin, :default => false, :null => false
      TrueClass :is_disabled, :default => true, :null => false
      TrueClass :is_approved, :default => false, :null => false
      DateTime :last_submit
      Integer :penalty, :default => 0
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

=begin
    create_table :solutions do
      foreign_key :user_id, :users
      foreign_key :task_id, :tasks
      primary_key [:user_id, :task_id]
    end
=end
    create_join_table({:user_id =>:users, :task_id =>:tasks}, :name => :solutions)

    create_table :scoreboard do
      primary_key :id
      foreign_key :user_id, :users, :unique => true
      Integer :points, :null => false, :default => 0
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

    create_table :register_confirms do
      primary_key :id
      String :user_hash, :unique => true, :null => false
      foreign_key :user_id, :users
      DateTime :time
    end

    create_table :password_recoveries do
      primary_key :id
      String :user_hash, :unique => true, :null => false
      foreign_key :user_id, :users
      DateTime :time
    end

  end
end
