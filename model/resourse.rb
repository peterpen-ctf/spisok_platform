#!/usr/bin/env ruby

require 'sequel'
class Resourse < Sequel::Model
  many_to_many :tasks
end
