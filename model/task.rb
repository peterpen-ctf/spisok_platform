#!/usr/bin/env ruby

require 'sequel'
class Task < Sequel::Model
  many_to_one :author, :class => :User
  many_to_one :contest
  many_to_one :category
  one_to_many :attempts
  many_to_many :resources

  plugin :validation_helpers

  def check_answer(given_answer)
    # TODO regexp check?
    self.answer_regex.to_s == given_answer.to_s
  end


  def validate
    validates_presence([:name, :description])
  end
end
