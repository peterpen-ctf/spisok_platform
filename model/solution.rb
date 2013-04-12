# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby

require 'sequel'
class Solution < Sequel::Model
=begin
  many_to_one :users
  many_to_one :tasks
=end
end
