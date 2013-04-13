#!/usr/bin/env ruby


def usage
  puts <<-USAGE
Usage:
  
  ruby load_tasks.rb TASK_DIR
  USAGE
end

path = ARGV[0] || ''

tasks_summary = Dir.glob(path + '/*/summary.yml')
if tasks_summary.empty?
  puts 'No tasks found.'
  usage
  exit 1
end

app = File.expand_path('../app', __FILE__)
require app
require 'yaml'


tasks_summary.each do |task_summary|
  yaml_task = YAML.load_file(task_summary)
  yaml_task['author'] = yaml_task['category'] = nil
  Task.create(yaml_task)
end

puts "Processed #{tasks_summary.length} tasks."
