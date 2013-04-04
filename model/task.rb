#!/usr/bin/env ruby

require 'sequel'
class Task < Sequel::Model
  many_to_one :author, :class => :User
  many_to_one :contest#, :class => :Contest
  one_to_many :attempts
  many_to_many :resourses
end
