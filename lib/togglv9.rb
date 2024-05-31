require_relative 'togglv9/version'

require_relative 'togglv9/connection'

require_relative 'togglv9/togglv9'
require_relative 'reportsv2'

# :mode => :compat will convert symbols to strings
Oj.default_options = { :mode => :compat }

module TogglV9
  NAME = "TogglV9 v#{TogglV9::VERSION}"
end
