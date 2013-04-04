#!/usr/bin/env ruby

require 'sequel'
class Solution < Sequel::Model
  many_to_one :users
  many_to_one :tasks
end
