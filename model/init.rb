
DB = Sequel.sqlite(__DIR__('../db/spisokdb.sqlite'))

require __DIR__('user')
require __DIR__('contest')
require __DIR__('category')
require __DIR__('task')
require __DIR__('solution')
require __DIR__('attempt')
require __DIR__('resourse')
