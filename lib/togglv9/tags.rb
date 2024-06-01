module TogglV9
  class API

    ##
    # ---------
    # :section: Tags
    #
    # name : The name of the tag (string, required, unique in workspace)
    # wid  : workspace ID, where the tag will be used (integer, required)

    def create_tag(workspace_id, params)
      requireParams(params, ['name'])
      post "workspaces/#{workspace_id}/tags", params
    end

    # ex: update_tag(12345, { :name => "same tame game" })
    def update_tag(workspace_id, tag_id, params)
      put "workspaces/#{workspace_id}/tags/#{tag_id}", params
    end

    def delete_tag(workspace_id, tag_id)
      delete "workspaces/#{workspace_id}/tags/#{tag_id}"
    end
  end
end
