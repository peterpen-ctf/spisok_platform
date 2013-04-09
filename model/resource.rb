# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby

require 'sequel'
class Resource < Sequel::Model
  many_to_many :tasks
end
