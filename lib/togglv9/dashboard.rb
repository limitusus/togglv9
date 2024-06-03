# frozen_string_literal: true

module TogglV9
  class API
    ##
    # ---------
    # :section: Dashboard
    #
    # See https://github.com/toggl/toggl_api_docs/blob/master/chapters/dashboard.md

    def dashboard(workspace_id)
      dashboard = {}
      dashboard['all_activity'] = all_activity(workspace_id)
      dashboard['most_active_user'] = most_active_user(workspace_id)
      dashboard['activity'] = top_activity(workspace_id)
      dashboard
    end

    private

    def all_activity(workspace_id)
      get "workspaces/#{workspace_id}/dashboard/all_activity"
    end

    def most_active_user(workspace_id)
      get "workspaces/#{workspace_id}/dashboard/most_active"
    end

    def top_activity(workspace_id)
      get "workspaces/#{workspace_id}/dashboard/top_activity"
    end
  end
end
