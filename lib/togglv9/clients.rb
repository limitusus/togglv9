module TogglV9
  class API
    ##
    # ---------
    # :section: Clients
    #
    # name  : The name of the client (string, required, unique in workspace)
    # wid   : workspace ID, where the client will be used (integer, required)
    # notes : Notes for the client (string, not required)
    # hrate : The hourly rate for this client (float, not required, available only for pro workspaces)
    # cur   : The name of the client's currency (string, not required, available only for pro workspaces)
    # at    : timestamp that is sent in the response, indicates the time client was last updated

    def create_client(workspace_id, params)
      requireParams(params, ['name', 'wid'])
      post "workspaces/#{workspace_id}/clients", params
    end

    def get_client(workspace_id, client_id)
      get "workspaces/#{workspace_id}/clients/#{client_id}"
    end

    def update_client(workspace_id, client_id, params)
      put "workspaces/#{workspace_id}/clients/#{client_id}", params
    end

    def delete_client(workspace_id, client_id)
      delete "workspaces/#{workspace_id}/clients/#{client_id}"
    end

    def get_client_projects(workspace_id, client_id, params = {})
      qs = "?clients=#{client_id}"
      active = params.has_key?('active') ? "&active=#{params['active']}" : ''
      get "workspaces/#{workspace_id}/projects#{qs}#{active}"
    end
  end
end
