# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby

require 'sequel'
class Category < Sequel::Model
  one_to_many :tasks
end
