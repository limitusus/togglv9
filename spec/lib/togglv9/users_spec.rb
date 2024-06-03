describe 'Users' do
  before :all do
    @toggl = TogglV9::API.new(Testing::API_TOKEN)
    @user = @toggl.me(all = true)
    @workspaces = @toggl.workspaces
    @workspace_id = @workspaces.first['id']
  end

  it 'returns /me' do
    expect(@user).to_not be_nil
    expect(@user['id']).to eq Testing::USER_ID
    expect(@user['fullname']).to eq Testing::USERNAME
    # expect(@user['image_url']).to eq 'https://assets.toggl.com/avatars/a5d106126b6bed8df283e708af0828ee.png'
    # expect(@user['timezone']).to eq 'Etc/UTC'
    # expect(@user['workspaces'].length).to eq 1
    # expect(@user['workspaces'].first['name']).to eq "togglv9's workspace"
  end

  it 'returns my_clients' do
    my_clients = @toggl.my_clients(@user)
    expect(my_clients).to be_empty
  end

  it 'returns my_projects' do
    my_projects = @toggl.my_projects(@user)
    expect(my_projects).to be_empty
  end

  it 'returns my_projects and my_deleted_projects' do
    # Create project
    project = @toggl.create_project(@workspace_id, { 'name' => 'my project' })

    my_project_ids         = @toggl.my_projects.map { |p| p['id'] }
    my_deleted_project_ids = @toggl.my_deleted_projects.map { |p| p['id'] }

    expect(my_project_ids).to eq [project['id']]
    expect(my_deleted_project_ids).not_to include(project['id'])

    # Delete project
    @toggl.delete_project(@workspace_id, project['id'])

    my_project_ids = @toggl.my_projects.map { |p| p['id'] }
    # FIXME: in v9 the /me response looks not to contain projects that were already deleted
    # my_deleted_project_ids = @toggl.my_deleted_projects.map { |p| p['id'] }

    expect(my_project_ids).to eq []
    # expect(my_deleted_project_ids).to include(project['id'])
  end

  it 'returns my_tags' do
    my_tags = @toggl.my_tags(@user)
    expect(my_tags).to be_empty
  end

  it 'returns my_tasks' do
    my_tasks = @toggl.my_tasks(@user)
    expect(my_tasks).to be_empty
  end

  it 'returns my_time_entries' do
    my_time_entries = @toggl.my_time_entries(@user)
    expect(my_time_entries).to be_empty
  end

  it 'returns my_workspaces' do
    my_workspaces = @toggl.my_workspaces(@user)
    expect(my_workspaces.length).to eq 1
  end

  context 'new user' do
    # FIXME: user creation API is deprecated https://engineering.toggl.com/changes/2023/11/02/v9-auth-endpoints-deprecation/index.html
    xit 'creates a new user' do
      now = Time.now.to_i
      user_info = {
        'email' => "test-#{now}+1@mailinator.com",
        'timezone' => 'Etc/UTC',
      }
      user_additional = {
        'password' => "password-#{now}+1",
        'tos_accepted' => 'true',
      }

      new_user = @toggl.create_user(user_info.merge(user_additional))
      expect(new_user).to include(user_info)
    end
  end
end
