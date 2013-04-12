# -*- encoding : utf-8 -*-

DB = Sequel.sqlite(__DIR__('../db/spisokdb.sqlite'))

# ActiveDirectory configuration
AD_HOST = 'serv2.math.spbu.ru'
AD_PORT = '636'
AD_BASE = 'dc=math,dc=spbu,dc=ru'
AD_DOMAIN = 'math.spbu.ru'
AD_USE_SSL = true
AD_TIMEOUT = 3

require __DIR__('user')
require __DIR__('contest')
require __DIR__('category')
require __DIR__('task')
require __DIR__('solution')
require __DIR__('attempt')
require __DIR__('resource')
require __DIR__('news')
require __DIR__('register_confirm')
