require 'spec_helper'

RSpec.describe Systemd::Journal do
  subject(:j) do
    Systemd::Journal.new(files: [journal_file]).tap do |j|
      j.seek(:head)
      j.move_next
    end
  end

  describe 'initialize' do
    subject(:j) { Systemd::Journal }

    it 'detects invalid argument combinations' do
      expect { j.new(path: '/',     files: []) }.to raise_error(ArgumentError)
      expect { j.new(container: '', files: []) }.to raise_error(ArgumentError)
      expect { j.new(container: '', path: '/') }.to raise_error(ArgumentError)
    end
  end

  describe 'query_unique' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_enumerate_unique)
        .and_return(-1)

      expect { j.query_unique(:_pid) }.to raise_error(Systemd::JournalError)
    end

    it 'lists all the unique values for the given field' do
      values     = j.query_unique(:_transport)
      transports = %w(syslog journal stdout kernel driver)

      expect(values.length).to eq(5)
      expect(values).to        include(*transports)
    end
  end

  describe 'disk_usage' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_usage)
        .and_return(-1)

      expect { j.disk_usage }.to raise_error(Systemd::JournalError)
    end

    it 'returns the disk usage of the example journal file' do
      pending "blocks? bytes?"
      expect(j.disk_usage).to eq(4005888)
    end
  end

  describe 'data_threshold' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_data_threshold)
        .and_return(-1)

      expect { j.data_threshold }.to raise_error(Systemd::JournalError)
    end

    it 'returns the default 64K' do
      expect(j.data_threshold).to eq(0x0010000)
    end
  end

  describe 'data_threshold=' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_set_data_threshold)
        .and_return(-1)

      expect { j.data_threshold = 10 }.to raise_error(Systemd::JournalError)
    end
  end

  describe 'read_field' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_data)
        .and_return(-1)

      expect { j.read_field(:message) }.to raise_error(Systemd::JournalError)
    end

    it 'returns the correct value' do
      expect(j.read_field(:_hostname)).to eq('arch')
    end
  end

  describe 'current_entry' do
    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_enumerate_data)
        .and_return(-1)

      expect { j.current_entry }.to raise_error(Systemd::JournalError)
    end

    it 'returns a JournalEntry with the correct values' do
      entry = j.current_entry
      expect(entry._hostname).to eq('arch')
      expect(entry.message).to   start_with('Allowing runtime journal')
    end
  end

  describe 'each' do
    it 'returns an enumerator' do
      expect(j.each.class).to be Enumerator
    end

    it 'throws a JournalError on invalid return code' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_seek_head)
        .and_return(-1)

      expect { j.each }.to raise_error(Systemd::JournalError)
    end

    it 'properly enumerates all the entries' do
      entries = j.each.map(&:message)

      expect(entries.first).to start_with('Allowing runtime journal')
      expect(entries.last).to  start_with('ROOT LOGIN ON tty1')
    end
  end

  context 'with catalog messages' do
    let(:message_id)   { 'f77379a8490b408bbe5f6940505a777b' }
    let(:message_text) { 'Subject: The Journal has been started' }

    describe 'catalog_for' do
      subject(:j) { Systemd::Journal }

      it 'throws a JournalError on invalid return code' do
        expect(Systemd::Journal::Native)
          .to receive(:sd_journal_get_catalog_for_message_id)
          .and_return(-1)

        expect { j.catalog_for(message_id) }.to raise_error(Systemd::JournalError)
      end

      it 'returns the correct catalog entry' do
        cat = Systemd::Journal.catalog_for(message_id)
        expect(cat).to start_with(message_text)
      end
    end

    describe 'current_catalog' do
      it 'throws a JournalError on invalid return code' do
        expect(Systemd::Journal::Native)
          .to receive(:sd_journal_get_catalog)
          .and_return(-1)

        expect { j.current_catalog }.to raise_error(Systemd::JournalError)
      end

      it 'returns the correct catalog entry' do
        # find first entry with a catalog
        j.move_next while !j.current_entry.catalog?

        expect(j.current_catalog).to start_with(message_text)
      end
    end
  end

end
