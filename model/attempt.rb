# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby

require 'sequel'
class Attempt < Sequel::Model
  many_to_one :user
  many_to_one :task
end
