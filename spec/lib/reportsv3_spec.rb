# frozen_string_literal: true

require 'fileutils'

describe 'ReportsV3' do
  before :all do
    toggl = TogglV9::API.new(Testing::API_TOKEN)
    workspaces = toggl.workspaces
    @workspace_id = workspaces.first['id']
  end

  it 'initializes with api_token' do
    reports = TogglV9::ReportsV3.new(api_token: Testing::API_TOKEN)
    reports.workspace_id = @workspace_id
    reports.list_clients
  end

  it 'does not initialize with bogus api_token' do
    reports = TogglV9::ReportsV3.new(api_token: '4880nqor1orr9n241sn08070q33oq49s')
    reports.workspace_id = @workspace_id
    expect { reports.list_clients }.to raise_error(RuntimeError, 'HTTP Status: 403')
  end

  describe '.toggl file' do
    before do
      @tmp_home = mktemp_dir
      @original_home = Dir.home
      ENV['HOME'] = @tmp_home
    end

    after do
      FileUtils.rm_rf(@tmp_home)
      ENV['HOME'] = @original_home
    end

    it 'initializes with .toggl file' do
      toggl_file = File.join(@tmp_home, '.toggl')
      File.write(toggl_file, Testing::API_TOKEN)

      reports = TogglV9::ReportsV3.new
      reports.workspace_id = @workspace_id
      clients = reports.list_clients
      expect(clients).to eq({})
    end

    it 'initializes with custom toggl file' do
      toggl_file = File.join(@tmp_home, 'my_toggl')
      File.write(toggl_file, Testing::API_TOKEN)

      reports = TogglV9::ReportsV3.new(toggl_api_file: toggl_file)
      reports.workspace_id = @workspace_id
      clients = reports.list_clients
      expect(clients).to eq({})
    end

    it 'raises error if .toggl file is missing' do
      expect { TogglV9::ReportsV3.new }.to raise_error(RuntimeError)
    end
  end

  context 'handles errors' do
    before :all do
      @reports = TogglV9::ReportsV3.new(api_token: Testing::API_TOKEN)
      @reports.workspace_id = @workspace_id
    end

    it 'retries a request up to 3 times if a 429 is received' do
      expect(@reports.conn).to receive(:post).exactly(3).times.and_return(
        MockResponse.new(429, {}, 'body')
      )
      expect { @reports.list_clients }.to raise_error(RuntimeError, 'HTTP Status: 429')
    end

    it 'retries a request after 429' do
      expect(@reports.conn).to receive(:post).twice.and_return(
        MockResponse.new(429, {}, 'body'),
        MockResponse.new(200, {}, '[{"id":65220674, "name":"test1"}, {"id":65220675, "name":"test2"}]')
      )
      expect(@reports.list_clients).to eq([{ 'id' => 65_220_674, 'name' => 'test1' }, { 'id' => 65_220_675, 'name' => 'test2' }])
    end
  end

  xcontext 'project', :pro_account do
    before :all do
      @toggl = TogglV9::API.new(Testing::API_TOKEN)
      @project_name = "Project #{Time.now.iso8601}"
      @project = @toggl.create_project(@workspace_id, { 'name' => @project_name })
    end

    after :all do
      @toggl.delete_project(@workspace_id, @project['id'])
    end

    it 'dashboard' do
      reports = TogglV9::ReportsV3.new(api_token: Testing::API_TOKEN)
      reports.workspace_id = @workspace_id
      project_dashboard = reports.project(@project['id'])

      expect(project_dashboard['name']).to eq @project_name
    end
  end

  context 'blank reports' do
    before :all do
      @reports = TogglV9::ReportsV3.new(api_token: Testing::API_TOKEN)
      @reports.workspace_id = @workspace_id
    end

    it 'summary' do
      expect(@reports.summary).to eq({ 'groups' => [] })
    end

    it 'weekly' do
      expect(@reports.weekly).to eq []
    end

    it 'details' do
      expect(@reports.details).to eq []
    end
  end

  context 'reports' do
    before :all do
      @toggl = TogglV9::API.new(Testing::API_TOKEN)
      time_entry_info = {
        'wid' => @workspace_id,
        'start' => @toggl.iso8601(DateTime.now),
        'duration' => 77,
      }

      @time_entry = @toggl.create_time_entry(@workspace_id, time_entry_info)

      @reports = TogglV9::ReportsV3.new(api_token: Testing::API_TOKEN)
      @reports.workspace_id = @workspace_id

      @tmp_home = mktemp_dir
      @original_home = Dir.home
      ENV['HOME'] = @tmp_home
    end

    after :all do
      @toggl.delete_time_entry(@workspace_id, @time_entry['id'])

      FileUtils.rm_rf(@tmp_home)
      ENV['HOME'] = @original_home
    end

    context 'JSON reports' do
      it 'summary' do
        summary = @reports.summary
        expect(summary['groups'].length).to eq 1
        expect(summary['groups'].first['sub_groups'].length).to eq 1
        expect(summary['groups'].first['sub_groups'].first['seconds']).to eq 77
      end

      it 'weekly' do
        weekly = @reports.weekly
        expect(weekly.length).to eq 1
        expect(weekly.first['user_id']).to eq Testing::USER_ID
        expect(weekly.first['seconds'][6]).to eq 77
      end

      it 'details' do
        details = @reports.details
        expect(details.length).to eq 1
        expect(details.first['user_id']).to eq Testing::USER_ID
        expect(details.first['username']).to eq Testing::USERNAME
        expect(details.first['row_number']).to eq 1
        expect(details.first['time_entries'].length).to eq 1
        expect(details.first['time_entries'].first['seconds']).to eq 77
      end
    end

    context 'CSV reports' do
      it 'summary' do
        filename = File.join(@tmp_home, 'summary.csv')
        @reports.write_summary(filename)
        expect(file_contains(filename, /00:01:17/))
      end

      it 'weekly' do
        filename = File.join(@tmp_home, 'weekly.csv')
        @reports.write_weekly(filename)
        expect(file_contains(filename, /00:01:17/))
      end

      it 'details' do
        filename = File.join(@tmp_home, 'details.csv')
        @reports.write_details(filename)
        expect(file_contains(filename, /00:01:17/))
      end
    end

    context 'PDF reports' do
      it 'summary' do
        filename = File.join(@tmp_home, 'summary.pdf')
        @reports.write_summary(filename)
        expect(file_is_pdf(filename))
      end

      it 'weekly' do
        filename = File.join(@tmp_home, 'weekly.pdf')
        @reports.write_weekly(filename)
        expect(file_is_pdf(filename))
      end

      it 'details' do
        filename = File.join(@tmp_home, 'details.pdf')
        @reports.write_details(filename)
        expect(file_is_pdf(filename))
      end
    end

    context 'XLS reports', :pro_account do
      it 'summary' do
        filename = File.join(@tmp_home, 'summary.xls')
        @reports.write_summary(filename)
        expect(file_is_xls(filename))
      end

      it 'details' do
        filename = File.join(@tmp_home, 'details.xls')
        @reports.write_details(filename)
        expect(file_is_xls(filename))
      end
    end
  end
end
