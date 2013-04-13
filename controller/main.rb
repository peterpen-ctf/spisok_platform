# -*- encoding : utf-8 -*-
# Default url mappings are:
# 
# * a controller called Main is mapped on the root of the site: /
# * a controller called Something is mapped on: /something
# 
# If you want to override this, add a line like this inside the class:
#
#  map '/otherurl'
#
# this will force the controller to be mounted on: /otherurl.
class MainController < Controller
  map '/'

  # the index action is called automatically when no other action is specified
  def index
    @title = 'SpisokCTF: новости'
    @news = News.all.sort {|a,b| b.update_time <=> a.update_time}
  end

  def scoreboard
    @title = 'Скорборд'
    @user_scores = Scoreboard.all.sort {|a,b| b.points <=> a.points}
  end

  # the string returned at the end of the function is used as the html body
  # if there is no template for the action. if there is a template, the string
  # is silently ignored
  def notemplate
    @title = 'Welcome to Ramaze!'

    return 'There is no \'notemplate.xhtml\' associated with this action.'
  end
end
