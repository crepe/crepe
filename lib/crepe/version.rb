module Crepe

  MAJOR   = 0
  MINOR   = 0
  PATCH   = 1
  PRE     = 'pre'
  BUILD   = nil
  

  VERSION = [[MAJOR, MINOR, PATCH].join('.'), PRE, BUILD].compact.join '-'

end
