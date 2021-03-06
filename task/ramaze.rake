# This file contains a predefined set of Rake tasks that can be useful when
# developing Ramaze applications. You're free to modify these tasks to your
# liking, they will not be overwritten when updating Ramaze.

namespace :ramaze do
  app = File.expand_path('../../app', __FILE__)

  desc 'Starts a Ramaze console using IRB'
  task :irb do
    require app
    require 'irb'
    require 'irb/completion'

    ARGV.clear
    IRB.start
  end

  # Pry can be installed using `gem install pry`.
  desc 'Starts a Ramaze console using Pry'
  task :pry do
    require app
    require 'pry'

    ARGV.clear
    Pry.start
  end

  # In case you want to use a different server or port you can freely modify
  # the options passed to `Ramaze.start()`.
  desc 'Starts Ramaze for development'
  task :start do
    require app
    require 'rack/recaptcha'

    Ramaze.middleware :dev do
      use Rack::Lint
      use Rack::CommonLogger, Ramaze::Log
      use Rack::ShowExceptions
      use Rack::ShowStatus
      use Rack::RouteExceptions
      use Rack::ConditionalGet
      use Rack::ETag, 'public'
      use Rack::Head
      use Ramaze::Reloader
      use Rack::Recaptcha, :public_key => '6LfM6t8SAAAAAH85nHYFRkhvlD2ptOlplA3jMDVr', :private_key => '6LfM6t8SAAAAAF3Dc4leL1K0_iKjNFGFD_f3umbm'
      run Ramaze.core
    end

    port = ARGV[1] || 7000
    puts "Starting server on port #{port}..."
    Ramaze.start(
      :adapter => :thin,
      :port    => port,
      :file    => __FILE__,
      :root    => Ramaze.options.roots,
      #:mode    => :live,
      :host   => '127.0.0.1',
    )
  end

  desc 'Lists all the routes defined using Ramaze::Route'
  task :routes do
    require app

    if Ramaze::Route::ROUTES.empty?
      abort 'No routes have been defined using Ramaze::Route'
    end

    spacing = Ramaze::Route::ROUTES.map { |k, v| k.to_s }
    spacing = spacing.sort { |l, r| r.length <=> l.length }[0].length

    Ramaze::Route::ROUTES.each do |from, to|
      puts "%-#{spacing}s => %s" % [from, to]
    end
  end

  desc 'Runs all migrations (sqlite)'
  task :dbup do
    command = 'sequel -m db/migrations/ sqlite://db/spisokdb.sqlite'
    puts "Running command:\n    #{command}"
    puts `#{command}`
  end

  desc 'Rolls back all migrations (sqlite)'
  task :dbdown do
    command = 'sequel -m db/migrations/ sqlite://db/spisokdb.sqlite -M 0'
    puts "Running command:\n    #{command}"
    puts `#{command}`
  end

  desc 'Reruns all migrations(sqlite)'
  task :dbreset => [:dbdown, :dbup]
end
