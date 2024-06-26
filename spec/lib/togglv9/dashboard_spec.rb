describe 'Dashboard' do
  before :all do
    @toggl = TogglV9::API.new(Testing::API_TOKEN)
    @workspaces = @toggl.workspaces
    @workspace_id = @workspaces.first['id']
  end

  it 'gets nil dashboard data' do
    dashboard = @toggl.dashboard(@workspace_id)
    expect(dashboard).to eq Hash['most_active_user' => {}, 'activity' => [], 'all_activity' => {}]
  end

  context 'gets dashboard time entries' do
    before :all do
      @new_time_entry = @toggl.start_time_entry(@workspace_id, { 'workspace_id' => @workspace_id, 'description' => 'new time entry +1' })
    end

    after :all do
      @toggl.delete_time_entry(@workspace_id, @new_time_entry['id'])
    end

    it 'gets dashboard data' do
      dashboard = @toggl.dashboard(@workspace_id)
      expect(dashboard['most_active_user']).to eq({})
      expect(dashboard['activity']).to_not be nil
      expect(dashboard['activity'].first['user_id']).to eq @toggl.me['id']
      expect(dashboard['activity'].first['project_id']).to be nil
      expect(dashboard['activity'].first['description']).to eq 'new time entry +1'
    end
  end
end
