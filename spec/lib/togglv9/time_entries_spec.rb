# frozen_string_literal: true

require 'date'

describe 'TimeEntries' do
  before :all do
    @toggl = TogglV9::API.new(Testing::API_TOKEN)
    @workspaces = @toggl.workspaces
    @workspace_id = @workspaces.first['id']
  end

  describe 'CRUD time entry' do
    before do
      time_entry_info = {
        'wid' => @workspace_id,
        'start' => @toggl.iso8601(DateTime.now),
        'duration' => 77,
      }

      @expected = time_entry_info.clone

      @time_entry = @toggl.create_time_entry(@workspace_id, time_entry_info)
    end

    after do
      @toggl.delete_time_entry(@workspace_id, @time_entry['id'])
    rescue RuntimeError => e
      raise e if e.message != 'HTTP Status: 404'
    end

    it 'creates a time entry' do
      expect(@time_entry['wid']).to eq @expected['wid']
      expect(@time_entry['duration']).to eq @expected['duration']
      expect(Time.parse(@time_entry['start'])).to eq Time.parse(@expected['start'])
    end

    it 'requires a workspace, project, or task to create' do
      time_entry_info = {
        'start' => @toggl.iso8601(DateTime.now),
        'duration' => 77,
      }

      expect do
        @toggl.create_time_entry(@workspace_id, time_entry_info)
      end.to raise_error(ArgumentError)
    end

    it 'gets a time entry' do
      retrieved_time_entry = @toggl.get_time_entry(@time_entry['id'])
      retrieved_time_entry.delete('guid')

      %w[start stop].each do |key|
        expect(retrieved_time_entry[key]).to eq_ts @time_entry[key]
        retrieved_time_entry.delete(key)
        @time_entry.delete(key)
      end
      expected = @time_entry.clone
      expected['tags'] ||= []
      expected['tag_ids'] ||= []
      expected.delete('uid')
      expected.delete('wid')

      expect(retrieved_time_entry).to eq expected
    end

    it 'updates a time entry' do
      time_entry_info = {
        'start' => '2010-02-13T23:31:30+00:00',
        'duration' => 42,
      }

      expected = time_entry_info.clone

      time_entry_updated = @toggl.update_time_entry(@workspace_id, @time_entry['id'], time_entry_info)
      expect(time_entry_updated['duration']).to eq expected['duration']
      expect(Time.parse(time_entry_updated['start'])).to eq Time.parse(expected['start'])
    end

    it 'deletes a time entry' do
      existing_time_entry = @toggl.get_time_entry(@time_entry['id'])
      expect(existing_time_entry.key?('server_deleted_at')).to be true
      expect(existing_time_entry['server_deleted_at']).to be_nil

      @toggl.delete_time_entry(@workspace_id, @time_entry['id'])

      expect { @toggl.get_time_entry(@time_entry['id']) }.to raise_error(RuntimeError, 'HTTP Status: 404')
    end
  end

  context 'with + UTC offset' do
    # ISO8601 times with positive '+' UTC offsets must be properly encoded

    before do
      time_entry_info = {
        'wid' => @workspace_id,
        'start' => '2016-01-22T12:08:14+02:00',
        'duration' => 77,
      }

      @expected = time_entry_info.clone

      @time_entry = @toggl.create_time_entry(@workspace_id, time_entry_info)
    end

    after do
      @toggl.delete_time_entry(@workspace_id, @time_entry['id'])
    rescue RuntimeError => e
      raise e if e.message != 'HTTP Status: 404'
    end

    it 'creates a time entry' do
      expect(@time_entry['wid']).to eq @expected['wid']
      expect(@time_entry['duration']).to eq @expected['duration']
      expect(Time.parse(@time_entry['start'])).to eq Time.parse(@expected['start'])
    end

    it 'requires a workspace, project, or task to create' do
      time_entry_info = {
        'start' => '2016-01-22T12:08:14+02:00',
        'duration' => 77,
      }

      expect do
        @toggl.create_time_entry(@workspace_id, time_entry_info)
      end.to raise_error(ArgumentError)
    end

    it 'gets a time entry' do
      retrieved_time_entry = @toggl.get_time_entry(@time_entry['id'])
      retrieved_time_entry.delete('guid')

      %w[start stop].each do |key|
        expect(retrieved_time_entry[key]).to eq_ts @time_entry[key]
        retrieved_time_entry.delete(key)
        @time_entry.delete(key)
      end
      expected = @time_entry.clone
      expected['tags'] ||= []
      expected['tag_ids'] ||= []
      expected.delete('uid')
      expected.delete('wid')

      expect(retrieved_time_entry).to eq expected
    end

    it 'updates a time entry' do
      time_entry_info = {
        'start' => '2010-02-13T23:31:30+07:00',
        'duration' => 42,
      }

      expected = time_entry_info.clone

      time_entry_updated = @toggl.update_time_entry(@workspace_id, @time_entry['id'], time_entry_info)
      expect(time_entry_updated['duration']).to eq expected['duration']
      expect(Time.parse(time_entry_updated['start'])).to eq Time.parse(expected['start'])
    end

    it 'deletes a time entry' do
      existing_time_entry = @toggl.get_time_entry(@time_entry['id'])
      expect(existing_time_entry.key?('server_deleted_at')).to be true

      @toggl.delete_time_entry(@workspace_id, @time_entry['id'])

      expect { @toggl.get_time_entry(@time_entry['id']) }.to raise_error(RuntimeError, 'HTTP Status: 404')
    end
  end

  context 'with multiple time entries' do
    before :all do
      time_entry_info = {
        'wid' => @workspace_id,
        'duration' => 77,
      }
      @now = DateTime.now

      start = { 'start' => @toggl.iso8601(@now - 9) }
      @time_entry_nine_days_ago = @toggl.create_time_entry(@workspace_id, time_entry_info.merge(start))
      @nine_days_ago_id = @time_entry_nine_days_ago['id']

      start = { 'start' => @toggl.iso8601(@now - 7) }
      @time_entry_last_week = @toggl.create_time_entry(@workspace_id, time_entry_info.merge(start))
      @last_week_id = @time_entry_last_week['id']

      start = { 'start' => @toggl.iso8601(@now) }
      @time_entry_now = @toggl.create_time_entry(@workspace_id, time_entry_info.merge(start))
      @now_id = @time_entry_now['id']

      start = { 'start' => @toggl.iso8601(@now + 7) }
      @time_entry_next_week = @toggl.create_time_entry(@workspace_id, time_entry_info.merge(start))
      @next_week_id = @time_entry_next_week['id']
    end

    after :all do
      TogglV9SpecHelper.delete_all_time_entries(@toggl)
    end

    it 'gets time entries (reaching back 9 days up till now)' do
      ids = @toggl.get_time_entries.map { |t| t['id'] }
      expect(ids.sort).to eq [@last_week_id, @now_id]
    end

    it 'gets time entries after start_date (up till now)' do
      ids = @toggl.get_time_entries({ start_date: @now - 1 }).map { |t| t['id'] }
      expect(ids.sort).to eq [@now_id]
    end

    it 'gets time entries between start_date and end_date' do
      ids = @toggl.get_time_entries({ start_date: @now - 1, end_date: @now + 1 }).map { |t| t['id'] }
      expect(ids.sort).to eq [@now_id]
    end

    it 'gets time entries in the future' do
      ids = @toggl.get_time_entries({ start_date: @now - 1, end_date: @now + 8 }).map { |t| t['id'] }
      expect(ids.sort).to eq [@now_id, @next_week_id]
    end
  end

  describe 'start and stop time entry' do
    it 'starts and stops a time entry' do
      time_entry_info = {
        'workspace_id' => @workspace_id,
        'description' => 'time entry description',
      }

      # start time entry
      running_time_entry = @toggl.start_time_entry(@workspace_id, time_entry_info)

      # get current time entry by '/current'
      time_entry_current = @toggl.get_current_time_entry
      # get current time entry by id
      time_entry_by_id = @toggl.get_time_entry(running_time_entry['id'])
      time_entry_by_id.delete('guid')

      # compare two methods of getting current time entry
      time_entry_current.delete('uid')
      time_entry_current.delete('wid')
      expect(time_entry_current).to eq time_entry_by_id

      # compare current time entry with running time entry
      expect(time_entry_by_id['start']).to eq_ts running_time_entry['start']
      time_entry_by_id.delete('start')
      running_time_entry.delete('start')

      running_time_entry['tags'] = [] if running_time_entry['tags'].nil?
      running_time_entry['tag_ids'] = [] if running_time_entry['tag_ids'].nil?
      running_time_entry.delete('uid')
      running_time_entry.delete('wid')
      expect(time_entry_by_id).to eq running_time_entry
      expect(time_entry_by_id.key?('stop')).to be true
      expect(time_entry_by_id['stop']).to be_nil

      # stop time entry
      stopped_time_entry = @toggl.stop_time_entry(@workspace_id, running_time_entry['id'])
      expect(stopped_time_entry.key?('stop')).to be true

      @toggl.delete_time_entry(@workspace_id, stopped_time_entry['id'])
    end

    it 'returns nil if there is no current time entry' do
      time_entry = @toggl.get_current_time_entry
      expect(time_entry).to eq({})
    end

    it 'requires a workspace, project, or task to start' do
      time_entry_info = {
        'description' => 'time entry description',
      }

      expect do
        @toggl.start_time_entry(@workspace_id, time_entry_info)
      end.to raise_error(ArgumentError)
    end
  end

  describe 'time entry tags' do
    before do
      time_entry_info = {
        'wid' => @workspace_id,
        'duration' => 7777,
      }
      @now = DateTime.now

      start = { 'start' => @toggl.iso8601(@now - 7) }
      @time7 = @toggl.create_time_entry(@workspace_id, time_entry_info.merge(start))

      start = { 'start' => @toggl.iso8601(@now - 6) }
      @time6 = @toggl.create_time_entry(@workspace_id, time_entry_info.merge(start))

      start = { 'start' => @toggl.iso8601(@now - 5) }
      @time5 = @toggl.create_time_entry(@workspace_id, time_entry_info.merge(start))

      start = { 'start' => @toggl.iso8601(@now - 4) }
      @time4 = @toggl.create_time_entry(@workspace_id, time_entry_info.merge(start))

      @time_entry_ids = [@time7['id'], @time6['id'], @time5['id'], @time4['id']]
    end

    after do
      TogglV9SpecHelper.delete_all_time_entries(@toggl)
      TogglV9SpecHelper.delete_all_tags(@toggl)
    end

    it 'adds and removes one tag' do
      # Add one tag
      @toggl.update_time_entries_tags_fixed(@workspace_id, @time_entry_ids,
                                            { 'tags' => ['money'], 'tag_action' => 'add' })

      time_entries = @toggl.get_time_entries
      tags = time_entries.map { |t| t['tags'] }
      expect(tags).to eq [
        ['money'],
        ['money'],
        ['money'],
        ['money']
      ]

      # Remove one tag
      @toggl.update_time_entries_tags_fixed(@workspace_id, @time_entry_ids,
                                            { 'tags' => ['money'], 'tag_action' => 'remove' })

      time_entries = @toggl.get_time_entries
      tags = time_entries.map { |t| t['tags'] }
      expect(tags).to eq [[], [], [], []]
    end

    it '"removes" a non-existent tag' do
      # Not tags to start
      time_entries = @toggl.get_time_entries
      tags = time_entries.map { |t| t['tags'] }
      expect(tags).to eq [[], [], [], []]

      # "Remove" a tag
      @toggl.update_time_entries_tags_fixed(@workspace_id, @time_entry_ids,
                                            { 'tags' => ['void'], 'tag_action' => 'remove' })

      # No tags to finish
      time_entries = @toggl.get_time_entries
      tags = time_entries.map { |t| t['tags'] }
      expect(tags).to eq [[], [], [], []]
    end

    it 'adds and removes multiple tags' do
      # Add multiple tags
      @toggl.update_time_entries_tags_fixed(@workspace_id, @time_entry_ids,
                                            { 'tags' => %w[billed productive], 'tag_action' => 'add' })

      time_entries = @toggl.get_time_entries
      tags = time_entries.map { |t| t['tags'] }
      expect(tags).to eq [
        %w[billed productive],
        %w[billed productive],
        %w[billed productive],
        %w[billed productive]
      ]

      # Remove multiple tags
      @toggl.update_time_entries_tags_fixed(@workspace_id, @time_entry_ids,
                                            { 'tags' => %w[billed productive], 'tag_action' => 'remove' })

      time_entries = @toggl.get_time_entries
      tags = time_entries.map { |t| t['tags'] }
      expect(tags).to eq [[], [], [], []]
    end

    it 'manages multiple tags' do
      # Add some tags
      @toggl.update_time_entries_tags_fixed(@workspace_id, @time_entry_ids,
                                            { 'tags' => %w[billed productive], 'tag_action' => 'add' })

      # Remove some tags
      @toggl.update_time_entries_tags_fixed(@workspace_id, [@time6['id'], @time4['id']],
                                            { 'tags' => ['billed'], 'tag_action' => 'remove' })

      # Add some tags
      @toggl.update_time_entries_tags_fixed(@workspace_id, [@time7['id']],
                                            { 'tags' => ['best'], 'tag_action' => 'add' })

      time7 = @toggl.get_time_entry(@time7['id'])
      time6 = @toggl.get_time_entry(@time6['id'])
      time5 = @toggl.get_time_entry(@time5['id'])
      time4 = @toggl.get_time_entry(@time4['id'])

      tags = [time7['tags'], time6['tags'], time5['tags'], time4['tags']]
      expect(tags).to eq [
        %w[best billed productive],
        ['productive'],
        %w[billed productive],
        ['productive']
      ]
    end
  end

  describe 'iso8601' do
    before :all do
      @ts = DateTime.new(2008, 6, 21, 13, 30, 2, '+09:00')
      @expected = '2008-06-21T13:30:02+09:00'
    end

    it 'formats a DateTime' do
      expect(@toggl.iso8601(@ts)).to eq @expected
    end

    it 'formats a Date' do
      @ts.to_date
      expect(@toggl.iso8601(@ts)).to eq @expected
    end

    it 'formats a Time' do
      @ts.to_time
      expect(@toggl.iso8601(@ts)).to eq @expected
    end

    it 'cannot format a FixNum' do
      expect { @toggl.iso8601(1_234_567_890) }.to raise_error(ArgumentError)
    end

    it 'cannot format a malformed timestamp' do
      expect { @toggl.iso8601('X') }.to raise_error(ArgumentError)
    end

    context 'with String' do
      it 'converts +00:00 to Zulu' do
        ts = '2015-08-21T09:21:02+00:00'
        expected = '2015-08-21T09:21:02Z'

        expect(@toggl.iso8601(ts)).to eq expected
      end

      it 'converts -00:00 to Z' do
        ts = '2015-08-21T09:21:02-00:00'
        expected = '2015-08-21T09:21:02Z'

        expect(@toggl.iso8601(ts)).to eq expected
      end

      it 'maintains an offset' do
        expect(@toggl.iso8601('2015-08-21T04:21:02-05:00')).to eq '2015-08-21T04:21:02-05:00'
      end
    end
  end

  RSpec::Matchers.define :eq_ts do |expected|
    # Matching actual time is necessary due to differing formats.
    # Example:
    # 1) POST time_entries/start returns 2015-08-21T07:28:20Z
    #    when GET time_entries/{time_entry_id} returns 2015-08-21T07:28:20+00:00
    # 2) 2015-08-21T03:20:30-05:00 and 2015-08-21T08:20:30+00:00 refer to
    #    the same moment in time, but one is in local time and the other in UTC
    match do |actual|
      DateTime.parse(actual) == DateTime.parse(expected)
    end
  end
end
