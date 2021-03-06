# -*- encoding : utf-8 -*-
#!/usr/bin/env ruby

require 'sequel'
class Contest < Sequel::Model
  one_to_many :tasks
  many_to_one :organizer, :class => :User

  def validate
    validates_presence([:name, :description, :organizer])
  end
end
