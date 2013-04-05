Run all migrations:

  sequel -m db/migrations/ sqlite://db/spisokdb.sqlite

Rollback all migrations:
  
  sequel -m db/migrations/ sqlite://db/spisokdb.sqlite -M 0

