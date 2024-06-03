# frozen_string_literal: true

describe 'Workspaces' do
  before :all do
    @toggl = TogglV9::API.new(Testing::API_TOKEN)
    @user = @toggl.me(true)
    @workspaces = @toggl.my_workspaces
    @workspace_id = @workspaces.first['id']
    @organization_id = @user['workspaces'].find { |w| w['id'] == @workspace_id }['organization_id']
    @project = @toggl.create_project(@workspace_id, { 'name' => 'project with a task' })
  end

  after :all do
    @toggl.delete_project(@workspace_id, @project['id'])
  end

  it 'shows users' do
    users = @toggl.users(@organization_id, @workspace_id)
    expect(users.length).to eq 2

    expect(users.first['user_id']).to eq Testing::USER_ID
    expect(users.first['email']).to   eq Testing::EMAIL
    expect(users.first['name']).to    eq Testing::USERNAME

    expect(users.last['user_id']).to      eq Testing::OTHER_USER_ID
    expect(users.last['email']).to        eq Testing::OTHER_EMAIL
    expect(users.last['name']).to         eq Testing::OTHER_USERNAME
    expect(users.last['workspace_id']).to eq @workspace_id
  end

  describe 'tasks', :pro_account do
    before do
      @task = @toggl.create_task(@workspace_id, @project['id'], 'name' => 'workspace task')
    end

    after do
      @toggl.delete_task(@workspace_id, @project['id'], @task['id'])
    end

    it 'shows tasks' do
      tasks = @toggl.tasks(@workspace_id)
      expect(tasks.length).to eq 1
      expect(tasks.first['name']).to eq 'workspace task'
      expect(tasks.first['pid']).to eq @project['id']
      expect(tasks.first['wid']).to eq @workspace_id
    end
  end
end
