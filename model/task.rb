#!/usr/bin/env ruby

require 'sequel'
class Task < Sequel::Model
  many_to_one :author, :class => :User
  many_to_one :contest
  many_to_one :category
  one_to_many :attempts
  many_to_many :resources
end
