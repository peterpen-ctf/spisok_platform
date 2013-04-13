
require 'sequel'

class Scoreboard < Sequel::Model(:scoreboard)

  def self.update_scores
    users = User.all
    users.each do |user|
      next if user.is_disabled
      user_id = user.id
      user_score = Scoreboard[user_id]
      if user_score.nil?
        user_score = Scoreboard.new :user_id => user_id
        user_score.save
      end
      user_points = user.solved_tasks.reduce(0) {|res,task| res + task.price}
      user_score.update :points => user_points
    end
  end

end