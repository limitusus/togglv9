# frozen_string_literal: true

require_relative 'clients'
require_relative 'dashboard'
require_relative 'project_users'
require_relative 'projects'
require_relative 'tags'
require_relative 'tasks'
require_relative 'time_entries'
require_relative 'users'
require_relative 'version'
require_relative 'workspaces'

module TogglV9
  TOGGL_API_URL = 'https://api.track.toggl.com/api/'

  class API
    include TogglV9::Connection

    TOGGL_API_V9_URL = "#{TOGGL_API_URL}v9/"

    attr_reader :conn

    def initialize(username = nil, password = API_TOKEN, opts = {})
      debug(debug: false)
      if username.nil? && password == API_TOKEN
        toggl_api_file = File.join(Dir.home, TOGGL_FILE)
        # logger.debug("toggl_api_file = #{toggl_api_file}")
        raise <<~EOMSG unless File.exist?(toggl_api_file)

          Expecting one of:
           1) api_token in file #{toggl_api_file}, or
           2) parameter: (api_token), or
           3) parameters: (username, password).
          \tSee https://github.com/kanet77/togglv9#togglv9api
          \tand https://github.com/toggl/toggl_api_docs/blob/master/chapters/authentication.md
        EOMSG

        username = File.read(toggl_api_file).strip
      end

      @conn = TogglV9::Connection.open(username, password,
                                       TOGGL_API_V9_URL, opts)
    end
  end
end
