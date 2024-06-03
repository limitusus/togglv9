describe 'Tags' do
  before :all do
    @toggl = TogglV9::API.new(Testing::API_TOKEN)
    @workspaces = @toggl.workspaces
    @workspace_id = @workspaces.first['id']
  end

  context 'new tag' do
    before :all do
      @tag = @toggl.create_tag(@workspace_id, { 'name' => 'new tag +1' })
      tag_ids = @toggl.my_tags.map { |t| t['id'] }
      expect(tag_ids).to eq [@tag['id']]
    end

    after :all do
      TogglV9SpecHelper.delete_all_tags(@toggl)
      tags = @toggl.my_tags
      expect(tags).to be_empty
    end

    it 'creates a tag' do
      expect(@tag).not_to be_nil
      expect(@tag['name']).to eq 'new tag +1'
      expect(@tag['notes']).to be_nil
      expect(@tag['workspace_id']).to eq @workspace_id
    end

    it 'returns tag associated with workspace_id' do
      tags = @toggl.tags(@workspace_id)
      expect(tags).not_to be_empty
      expect(tags.first['name']).to eq 'new tag +1'
      expect(tags.first['workspace_id']).to eq @workspace_id
    end
  end

  context 'updated tag' do
    before :each do
      @tag = @toggl.create_tag(@workspace_id, { 'name' => 'tag to update' })
    end

    after :each do
      @toggl.delete_tag(@workspace_id, @tag['id'])
    end

    it 'updates tag data' do
      new_values = {
        'name' => 'TAG-NEW',
      }

      tag = @toggl.update_tag(@workspace_id, @tag['id'], new_values)
      expect(tag).to include(new_values)
    end
  end
end
