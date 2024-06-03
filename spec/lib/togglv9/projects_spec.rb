# frozen_string_literal: true

describe 'Projects' do
  before :all do
    @toggl = TogglV9::API.new(Testing::API_TOKEN)
    @workspaces = @toggl.workspaces
    @workspace_id = @workspaces.first['id']
  end

  it 'gets {} if there are no workspace projects' do
    projects = @toggl.projects(@workspace_id)
    expect(projects).to be_empty
  end

  context 'new project' do
    before :all do
      @project = @toggl.create_project(@workspace_id, { 'name' => 'new project +1' })
      project_ids = @toggl.my_projects.map { |p| p['id'] }
      expect(project_ids).to eq [@project['id']]
    end

    after :all do
      TogglV9SpecHelper.delete_all_projects(@toggl)
      projects = @toggl.my_projects
      expect(projects).to be_empty
    end

    it 'creates a project' do
      expect(@project).not_to be_nil
      expect(@project['name']).to eq 'new project +1'
      expect(@project['billable']).to be_nil
      expect(@project['is_private']).to be true
      expect(@project['active']).to be true
      expect(@project['template']).to be_nil
      expect(@project['auto_estimates']).to be_nil
      expect(@project['wid']).to eq @workspace_id
    end

    it 'gets project data' do
      project = @toggl.get_project(@workspace_id, @project['id'])
      expect(project).not_to be_nil
      expect(project['wid']).to eq @project['wid']
      expect(project['name']).to eq @project['name']
      expect(project['billable']).to eq @project['billable']
      expect(project['is_private']).to eq @project['is_private']
      expect(project['active']).to eq @project['active']
      expect(project['template']).to eq @project['template']
      expect(project['auto_estimates']).to eq @project['auto_estimates']
      expect(project['at']).not_to be_nil
    end

    it 'gets project users' do
      users = @toggl.get_project_users(@workspace_id, @project['id'])
      expect(users.length).to eq 1
      expect(users.first['user_id']).to eq Testing::USER_ID
      expect(users.first['manager']).to be true
    end
  end

  context 'updated project' do
    before do
      @project = @toggl.create_project(@workspace_id, { 'name' => 'project to update' })
    end

    after do
      @toggl.delete_project(@workspace_id, @project['id'])
    end

    it 'updates project data' do
      new_values = {
        'name' => 'PROJECT-NEW',
        'is_private' => false,
        'active' => false,
        'auto_estimates' => true,
      }
      project = @toggl.update_project(@workspace_id, @project['id'], new_values)
      expect(project).to include(new_values)
    end

    it 'updates Pro project data', :pro_account do
      new_values = {
        'template' => true,
        'billable' => true,
      }
      project = @toggl.update_project(@workspace_id, @project['id'], new_values)
      expect(project).to include(new_values)
    end
  end

  context 'multiple projects' do
    after :all do
      TogglV9SpecHelper.delete_all_projects(@toggl)
    end

    it 'deletes multiple projects' do
      # start with no projects
      expect(@toggl.projects(@workspace_id)).to be_empty

      p1 = @toggl.create_project(@workspace_id, { 'name' => 'p1' })
      p2 = @toggl.create_project(@workspace_id, { 'name' => 'p2' })
      p3 = @toggl.create_project(@workspace_id, { 'name' => 'p3' })

      # see 3 new projects
      expect(@toggl.projects(@workspace_id).length).to eq 3

      p_ids = [p1, p2, p3].map { |p| p['id'] }
      @toggl.delete_projects(@workspace_id, p_ids)

      # end with no projects
      expect(@toggl.projects(@workspace_id)).to be_empty
    end
  end
end
