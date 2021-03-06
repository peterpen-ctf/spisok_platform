#!/usr/bin/env ruby
# -*- encoding : utf-8 -*-
`sequel sqlite://db/spisokdb.sqlite -m db/migrations -M 0`
`sequel sqlite://db/spisokdb.sqlite -m db/migrations`

require_relative 'app'
p DB

user1 = User.create :email => "user1@a.r", :full_name => 'asdf'
user2 = User.create :email => "user2@a.r", :full_name => 'asdf'
user3 = User.create :email => "user3@a.r", :full_name => 'asdf'

p User.all

task1 = Task.create :name => "task1", :description => 'find the key'
contest1 = Contest.create :name => "contest1"

contest1.organizer = user1
task1.author = user2
task1.contest = contest1

task1.save
contest1.save

p Task.all

ppc = Category.create :name => "ppc"
task1.category = ppc

p ppc

p ppc.tasks
task1.save
p task1
p ppc.tasks

p user2.submitted_tasks

new_ppc = Category.first(:name => "ppc")
p new_ppc.tasks

new_c1 = Contest.first(:name => "contest1")
p new_c1.tasks
p task1.contest

p user1.submitted_contests

r1 = Resource.create :name => "r1"
r2 = Resource.create :name => "r2"

task1.add_resource r1
r2.add_task task1
p task1.resources
