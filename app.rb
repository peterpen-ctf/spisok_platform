# This file contains your application, it requires dependencies and necessary
# parts of the application.
require 'rubygems'
require 'ramaze'
require 'sequel'

# Make sure that Ramaze knows where you are
Ramaze.options.roots = [__DIR__]

# Load helpers
require __DIR__('helper/string_helper')
require __DIR__('helper/password_helper')

# Initialize models and controllers
require __DIR__('model/init')
require __DIR__('controller/init')
