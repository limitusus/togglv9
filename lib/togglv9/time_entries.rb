module TogglV9
  class API

    ##
    # ---------
    # :section: Time Entries
    #
    # https://github.com/toggl/toggl_api_docs/blob/master/chapters/time_entries.md
    #
    # description  : (string, strongly suggested to be used)
    # wid          : workspace ID (integer, required if pid or tid not supplied)
    # pid          : project ID (integer, not required)
    # tid          : task ID (integer, not required)
    # billable     : (boolean, not required, default false, available for pro workspaces)
    # start        : time entry start time (string, required, ISO 8601 date and time)
    # stop         : time entry stop time (string, not required, ISO 8601 date and time)
    # duration     : time entry duration in seconds. If the time entry is currently running,
    #                the duration attribute contains a negative value,
    #                denoting the start of the time entry in seconds since epoch (Jan 1 1970).
    #                The correct duration can be calculated as current_time + duration,
    #                where current_time is the current time in seconds since epoch. (integer, required)
    # created_with : the name of your client app (string, required)
    # tags         : a list of tag names (array of strings, not required)
    # duronly      : should Toggl show the start and stop time of this time entry? (boolean, not required)
    # at           : timestamp that is sent in the response, indicates the time item was last updated

    def create_time_entry(workspace_id, params)
      params['created_with'] = TogglV9::NAME unless params.has_key?('created_with')
      requireParams(params, ['wid', 'start', 'duration', 'created_with'])
      post "workspaces/#{workspace_id}/time_entries", params
    end

    def start_time_entry(workspace_id, params)
      params['created_with'] = TogglV9::NAME unless params.has_key?('created_with')
      requireParams(params, ['workspace_id'])
      params["start"] = iso8601(Time.now)
      params["duration"] = -1
      post "workspaces/#{workspace_id}/time_entries", params
    end

    def stop_time_entry(workspace_id, time_entry_id)
      patch "workspaces/#{workspace_id}/time_entries/#{time_entry_id}/stop", {}
    end

    def get_time_entry(time_entry_id)
      get "me/time_entries/#{time_entry_id}"
    end

    def get_current_time_entry
      get "me/time_entries/current"
    end

    def update_time_entry(workspace_id, time_entry_id, params)
      put "workspaces/#{workspace_id}/time_entries/#{time_entry_id}", params
    end

    def delete_time_entry(workspace_id, time_entry_id)
      delete "workspaces/#{workspace_id}/time_entries/#{time_entry_id}"
    end

    def iso8601(timestamp)
      return nil if timestamp.nil?
      if timestamp.is_a?(DateTime) or timestamp.is_a?(Date) or timestamp.is_a?(Time)
        formatted_ts = timestamp.iso8601
      elsif timestamp.is_a?(String)
        formatted_ts = DateTime.parse(timestamp).iso8601
      else
        raise ArgumentError, "Can't convert #{timestamp.class} to ISO-8601 Date/Time"
      end
      return formatted_ts.sub('+00:00', 'Z')
    end

    def get_time_entries(dates = {})
      start_date = dates[:start_date]
      end_date = dates[:end_date]
      params = []
      start_date = Time.now - 9 * 24 * 60 * 60 if start_date.nil?
      end_date = Time.now if end_date.nil?
      params.push("start_date=#{iso8601(start_date)}")
      params.push("end_date=#{iso8601(end_date)}")
      get "me/time_entries%s" % [params.empty? ? "" : "?#{params.join('&')}"]
    end

    # Example params: {'tags' =>['billed','productive'], 'tag_action' => 'add'}
    # tag_action can be 'add' or 'remove'
    def update_time_entries_tags(workspace_id, time_entry_ids, params)
      return if time_entry_ids.nil?
      requireParams(params, ['tags', 'tag_action'])
      patch_params = [
        {
          'op' => params['tag_action'],
          'path' => '/tags',
          'value' => params['tags'],
        }
      ]
      patch "workspaces/#{workspace_id}/time_entries/#{time_entry_ids.join(',')}", patch_params
    end

    # TEMPORARY FIXED version of API issue
    # see https://github.com/toggl/toggl_api_docs/issues/20 for more info
    def update_time_entries_tags_fixed(workspace_id, time_entry_ids, params)
      time_entries = update_time_entries_tags(workspace_id, time_entry_ids, params)
      return time_entries if params['tag_action'] == 'add'

      time_entries_for_removing_all_tags_ids = []
      [].push(time_entries).flatten.map! do |time_entry|
        unless time_entry['tags'].nil?
          time_entry['tags'] = time_entry['tags'] - params['tags']
          time_entries_for_removing_all_tags_ids << time_entry['id'] if time_entry['tags'].empty?
        end
        time_entry
      end

      remove_params = {'tags' => []}
      put "time_entries/#{time_entries_for_removing_all_tags_ids.join(',')}", { 'time_entry' => remove_params } unless time_entries_for_removing_all_tags_ids.empty?

      time_entries
    end
  end
end
