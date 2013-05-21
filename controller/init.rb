# -*- encoding : utf-8 -*-
# Define a subclass of Ramaze::Controller holding your defaults for all controllers. Note
# that these changes can be overwritten in sub controllers by simply calling the method
# but with a different value.

class Controller < Ramaze::Controller
  # Default options
  layout :default
  helper :xhtml
  engine :etanni

  # User helper
  helper :user
  trait :user_model => User

  # Form helper
  helper :blue_form

  # CSRF helper
  helper :csrf

  attr_reader :current_user
  def initialize
    @current_user = logged_in? ? user : nil
  end

  def logged_admin?
    logged_in? and @current_user.is_admin
  end


  # Custom 404 processing
  def self.action_missing(path)
    return if path == '/error'
    try_resolve('/error')
  end

  # Disable default layout for error processing.
  # Know better way?
  set_layout '' => [:error]
  LLAMA_DIR = 'llamas/'
  def error
    all_llamas = Dir.glob('public/' + LLAMA_DIR + '*')
    @img_path = LLAMA_DIR + File.basename(all_llamas.sample)
    render_file("#{Ramaze.options.views[0]}/error.xhtml")
  end

  def get_controller_class
    self.class
  end

end


# Here you can require all your other controllers. Note that if you have multiple
# controllers you might want to do something like the following:
#
#  Dir.glob('controller/*.rb').each do |controller|
#    require(controller)
#  end
#
require __DIR__('main')
require __DIR__('user')
require __DIR__('task')
require __DIR__('news')
require __DIR__('attempt')
require __DIR__('resource')
