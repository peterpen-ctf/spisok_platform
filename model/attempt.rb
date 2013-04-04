#!/usr/bin/env ruby

require 'sequel'
class Attempt < Sequel::Model
  many_to_one :users
  many_to_one :tasks
end
