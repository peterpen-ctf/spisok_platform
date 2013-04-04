#!/usr/bin/env ruby

require 'sequel'
class User < Sequel::Model
  one_to_many :submitted_tasks, :class => :Task
  one_to_many :submitted_contests, :class => :Contest
  one_to_many :attempts
end
