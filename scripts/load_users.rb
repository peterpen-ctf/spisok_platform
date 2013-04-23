#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-

app = File.expand_path('../../app', __FILE__)


while user = ARGF.gets
  next unless user =~ /^.*VALUES\((.*)\);$/
  values = $1.split ',' 
  raise if values.length != 7

  values.insert(4, 'NULL')
  values.insert(7, "'f'")
  values.insert(9, "0")
  puts "INSERT INTO \"users\" VALUES(" + values.join(',') + ');'
end

