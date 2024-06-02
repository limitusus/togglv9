describe 'Clients' do
  before :all do
    @toggl = TogglV9::API.new(Testing::API_TOKEN)
    @workspaces = @toggl.workspaces
    @workspace_id = @workspaces.first['id']
  end

  it 'gets {} if there are no workspace clients' do
    client = @toggl.clients(@workspace_id)
    expect(client).to be_empty
  end

  context 'new client' do
    before :all do
      @client = @toggl.create_client(@workspace_id, { 'name' => 'new client +1', 'wid' => @workspace_id })
      client_ids = @toggl.my_clients.map { |c| c['id'] }
      expect(client_ids).to eq [ @client['id'] ]
    end

    after :all do
      TogglV9SpecHelper.delete_all_clients(@toggl)
      clients = @toggl.my_clients
      expect(clients).to be_empty
    end

    it 'gets a client' do
      client_ids = @toggl.clients(@workspace_id).map { |c| c['id'] }
      expect(client_ids).to eq [ @client['id'] ]
    end

    it 'gets a workspace client' do
      client_ids = @toggl.clients(@workspace_id).map { |c| c['id'] }
      expect(client_ids).to eq [ @client['id'] ]
    end

    context 'multiple clients' do
      before :all do
        @client2 = @toggl.create_client(@workspace_id, { 'name' => 'new client 2', 'wid' => @workspace_id })
      end

      after :all do
        @toggl.delete_client(@workspace_id, @client2['id'])
      end

      it 'gets clients' do
        client_ids = @toggl.clients(@workspace_id).map { |c| c['id'] }
        expect(client_ids).to match_array [ @client['id'], @client2['id'] ]
      end

      it 'gets workspace clients' do
        client_ids = @toggl.clients(@workspace_id).map { |c| c['id'] }
        expect(client_ids).to match_array [ @client['id'], @client2['id'] ]
      end
    end

    it 'creates a client' do
      expect(@client).to_not be nil
      expect(@client['name']).to eq 'new client +1'
      expect(@client['notes']).to eq nil
      expect(@client['wid']).to eq @workspace_id
    end

    it 'gets client data' do
      client = @toggl.get_client(@workspace_id, @client['id'])
      expect(client).to_not be nil
      expect(client['name']).to eq @client['name']
      expect(client['wid']).to eq @client['wid']
      expect(client['notes']).to eq @client['notes']
      expect(client['at']).to_not be nil
    end

    context 'client projects' do
      it 'gets {} if there are no client projects' do
        projects = @toggl.get_client_projects(@workspace_id, @client['id'])
        expect(projects).to be_empty
      end

      context 'new client projects' do
        before :all do
          @project = @toggl.create_project(@workspace_id, { 'name' => 'project', 'wid' => @workspace_id, 'cid' => @client['id'] })
        end

        after :all do
          TogglV9SpecHelper.delete_all_projects(@toggl)
        end

        it 'gets a client project' do
          projects = @toggl.get_client_projects(@workspace_id, @client['id'])
          project_ids = projects.map { |p| p['id'] }
          expect(project_ids).to eq [ @project['id'] ]
        end

        it 'gets multiple client projects' do
          project2 = @toggl.create_project(@workspace_id, { 'name' => 'project2', 'wid' => @workspace_id, 'cid' => @client['id'] })

          projects = @toggl.get_client_projects(@workspace_id, @client['id'])
          project_ids = projects.map { |p| p['id'] }
          expect(project_ids).to match_array [ @project['id'], project2['id'] ]

          @toggl.delete_project(@workspace_id, project2['id'])
        end
      end
    end
  end

  context 'updated client' do
    before :each do
      @client = @toggl.create_client(@workspace_id, { 'name' => 'client to update', 'wid' => @workspace_id })
    end

    after :each do
      @toggl.delete_client(@workspace_id, @client['id'])
    end

    it 'updates client data' do
      new_values = {
        'name' => 'CLIENT-NEW',
        'notes' => 'NOTES-NEW',
      }

      client = @toggl.update_client(@workspace_id, @client['id'], new_values)
      expect(client).to include(new_values)
    end
  end
end
