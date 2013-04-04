#!/usr/bin/env ruby
`sequel sqlite://db/spisokdb.sqlite -m db/migrations -M 0`
`sequel sqlite://db/spisokdb.sqlite -m db/migrations`

require_relative 'app'
p DB

user1 = User.create :name => "user1"
user2 = User.create :name => "user2"
user3 = User.create :name => "user3"

p User.all

task1 = Task.create :name => "task1"
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