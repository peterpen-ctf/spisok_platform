
require 'sequel'

class Scoreboard < Sequel::Model(:scoreboard)

  many_to_one :user

  def self.update_scores
    users = User.all
    users.each do |user|
      user_id = user.id

      # Make sure that disabled user is not in a scoreboard
      if user.is_disabled
        user_score = Scoreboard.first :user_id => user_id
        user_score.destroy unless user_score.nil?
        next
      end

      user_score = Scoreboard.first :user_id => user_id
      if user_score.nil?
        user_score = Scoreboard.new :user_id => user_id
        user_score.save
      end
      user_points = user.solved_tasks.reduce(0) {|res,task| res + task.price.to_i}
      user_score.update :points => user_points
    end
  end

end
