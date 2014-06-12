require 'spec_helper'

describe Systemd::Journal do

  describe '#initialize' do
    it 'opens a directory if a path is passed' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_open_directory)
      expect(Systemd::Journal::Native).to_not receive(:sd_journal_open)

      Systemd::Journal.new(path: '/path/to/journal')
    end

    it 'accepts flags as an argument' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_open).with(
        anything,
        1234
      )

      Systemd::Journal.new(flags: 1234)
    end

    it 'accepts a files argument to open specific files' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_open_files)
      Systemd::Journal.new(files: ['/path/to/journal/1', '/path/to/journal/2'])
    end

    it 'accepts a machine name to open a container' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_open_container)
      Systemd::Journal.new(container: 'bobs-machine')
    end

    it 'raises a Journal Error if a native call fails' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_open).and_return(-1)
      expect { Systemd::Journal.new }.to raise_error(Systemd::JournalError)
    end

    it 'raises an argument error if conflicting options are passed' do
      expect do
        Systemd::Journal.new(path: 'p', files: %w(a b))
      end.to raise_error(ArgumentError)
      expect do
        Systemd::Journal.new(container: 'c', files: %w(a b))
      end.to raise_error(ArgumentError)
    end
  end

  describe '#move' do
    it 'calls move_next_skip if the value is positive' do
      j = Systemd::Journal.new
      expect(j).to receive(:move_next_skip).with(5)
      j.move(5)
    end

    it 'calls move_next_previous otherwise' do
      j = Systemd::Journal.new
      expect(j).to receive(:move_previous_skip).with(5)
      j.move(-5)
    end
  end

  %w(next previous).each do |direction|
    describe "#move_#{direction}" do
      it 'returns true on a successful move' do
        j = Systemd::Journal.new
        expect(Systemd::Journal::Native).to receive(:"sd_journal_#{direction}")
          .and_return(1)

        expect(j.send(:"move_#{direction}")).to be true
      end

      it 'returns false on EOF' do
        j = Systemd::Journal.new
        expect(Systemd::Journal::Native).to receive(:"sd_journal_#{direction}")
          .and_return(0)

        expect(j.send(:"move_#{direction}")).to be false
      end

      it 'raises an exception on failure' do
        j = Systemd::Journal.new
        expect(Systemd::Journal::Native).to receive(:"sd_journal_#{direction}")
          .and_return(-1)

        expect do
          j.send(:"move_#{direction}")
        end.to raise_error(Systemd::JournalError)
      end
    end

    describe "#move_#{direction}_skip" do
      it 'returns the number of records moved by' do
        expect(Systemd::Journal::Native).to receive(:"sd_journal_#{direction}_skip")
          .with(anything, 10)
          .and_return(10)

        expect(Systemd::Journal.new.send(:"move_#{direction}_skip", 10)).to eq(10)
      end

      it 'raises an exception on failure' do
        expect(Systemd::Journal::Native).to receive(:"sd_journal_#{direction}_skip")
          .with(anything, 10)
          .and_return(-1)

        j = Systemd::Journal.new

        expect do
          j.send(:"move_#{direction}_skip", 10)
        end.to raise_error(Systemd::JournalError)
      end
    end
  end

  describe '#each' do
    it 'should reposition to the head of the journal' do
      j = Systemd::Journal.new
      expect(j).to receive(:seek).with(:head).and_return(0)
      allow(j).to receive(:move_next).and_return(nil)
      j.each { nil }
    end

    it 'should return an enumerator if no block is given' do
      j = Systemd::Journal.new
      expect(j.each.class).to eq(Enumerator)
    end

    it 'should return each entry in the journal' do
      entries = [{ '_PID' => 1 }, { '_PID' => 2 }]
      entry   = nil

      j = Systemd::Journal.new
      allow(j).to receive(:seek).and_return(0)
      allow(j).to receive(:current_entry) { entry }
      allow(j).to receive(:move_next)     { entry = entries.shift }

      expect(j.map { |e| e['_PID'] }).to eq([1, 2])
    end

  end

  describe '#seek' do
    it 'moves to the first entry of the file' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_seek_head)
        .and_return(0)

      expect(j.seek(:head)).to be true
    end

    it 'moves to the last entry of the file' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_seek_tail)
        .and_return(0)

      expect(j.seek(:tail)).to be true
    end

    it 'seeks based on time when a time is provided' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_seek_realtime_usec)
        .and_return(0)

      expect(j.seek(Time.now)).to be true
    end

    it 'seeks based on a cursor when a string is provided' do
      j = Systemd::Journal.new

      expect(Systemd::Journal::Native).to receive(:sd_journal_seek_cursor)
        .with(anything, '123')
        .and_return(0)

      j.seek('123')
    end

    it 'throws an exception if it doesnt understand the type' do
      j = Systemd::Journal.new
      expect { j.seek(Object.new) }.to raise_error(ArgumentError)
    end
  end

  describe '#read_field' do
    it 'raises an exception if the call fails' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_data)
        .and_return(-1)

      expect { j.read_field(:message) }.to raise_error(Systemd::JournalError)
    end

    it 'parses the returned value correctly.' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_data) do |_, _, out_ptr, len_ptr|
          dummy = 'MESSAGE=hello world'
          out_ptr.write_pointer(FFI::MemoryPointer.from_string(dummy))
          len_ptr.write_size_t(dummy.size)
          0
        end

      expect(j.read_field(:message)).to eq('hello world')
    end
  end

  describe '#current_entry' do
    before(:each) do
      expect(Systemd::Journal::Native).to receive(:sd_journal_restart_data)
        .and_return(nil)
    end

    it 'raises an exception if the call fails' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_enumerate_data)
        .and_return(-1)

      expect { j.current_entry }.to raise_error(Systemd::JournalError)
    end

    it 'returns the correct data' do
      j = Systemd::Journal.new
      results = ['_PID=100', 'MESSAGE=hello world']

      expect(Systemd::Journal::Native).to receive(:sd_journal_enumerate_data)
        .exactly(3).times do |_, out_ptr, len_ptr|
          if results.any?
            x = results.shift
            out_ptr.write_pointer(FFI::MemoryPointer.from_string(x))
            len_ptr.write_size_t(x.length)
            1
          else
            0
          end
        end

      entry = j.current_entry

      expect(entry._pid).to    eq('100')
      expect(entry.message).to eq('hello world')
    end
  end

  describe '#query_unique' do
    before(:each) do
      expect(Systemd::Journal::Native).to receive(:sd_journal_restart_unique)
        .and_return(nil)
    end

    it 'raises an exception if the call fails' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_query_unique)
        .and_return(-1)

      expect { j.query_unique(:_pid) }.to raise_error(Systemd::JournalError)
    end

    it 'raises an exception if the call fails (2)' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_query_unique)
        .and_return(0)

      expect(Systemd::Journal::Native).to receive(:sd_journal_enumerate_unique)
        .and_return(-1)

      expect { j.query_unique(:_pid) }.to raise_error(Systemd::JournalError)
    end

    it 'returns the correct data' do
      j = Systemd::Journal.new
      results = ['_PID=100', '_PID=200', '_PID=300']

      expect(Systemd::Journal::Native).to receive(:sd_journal_query_unique)
        .and_return(0)

      expect(Systemd::Journal::Native).to receive(:sd_journal_enumerate_unique)
        .exactly(4).times do |_, out_ptr, len_ptr|
          if results.any?
            x = results.shift
            out_ptr.write_pointer(FFI::MemoryPointer.from_string(x))
            len_ptr.write_size_t(x.length)
            1
          else
            0
          end
        end

      expect(j.query_unique(:_pid)).to eq(%w(100 200 300))
    end

  end

  describe '#wait' do
    it 'raises an exception if the call fails' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_wait).and_return(-1)

      j = Systemd::Journal.new
      expect { j.wait(100) }.to raise_error(Systemd::JournalError)
    end

    it 'returns the reason we were woken up' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_wait)
        .and_return(:append)

      expect(j.wait(100)).to eq(:append)
    end

    it 'returns nil if we reached the timeout.' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_wait)
        .and_return(:nop)

      expect(j.wait(100)).to be nil
    end
  end

  describe '#add_filter' do
    it 'raises an exception if the call fails' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_add_match)
        .and_return(-1)

      expect do
        j.add_filter(:message, 'test')
      end.to raise_error(Systemd::JournalError)
    end

    it 'formats the arguments appropriately' do
      expect(Systemd::Journal::Native).to receive(:sd_journal_add_match)
        .with(anything, 'MESSAGE=test', 'MESSAGE=test'.length)
        .and_return(0)

      Systemd::Journal.new.add_filter(:message, 'test')
    end
  end

  describe '#add_filters' do
    it 'calls add_filter for each parameter' do
      j = Systemd::Journal.new
      expect(j).to receive(:add_filter).with(:priority, 1)
      expect(j).to receive(:add_filter).with(:_exe, '/usr/bin/sshd')

      j.add_filters(priority: 1, _exe: '/usr/bin/sshd')
    end

    it 'expands array arguments to multiple add_filter calls' do
      j = Systemd::Journal.new
      expect(j).to receive(:add_filter).with(:priority, 1)
      expect(j).to receive(:add_filter).with(:priority, 2)
      expect(j).to receive(:add_filter).with(:priority, 3)

      j.add_filters(priority: [1, 2, 3])
    end
  end

  describe '#filter' do
    it 'clears the existing filters' do
      j = Systemd::Journal.new
      expect(j).to receive(:clear_filters)

      j.filter({})
    end

    it 'adds disjunctions between terms' do
      j = Systemd::Journal.new
      allow(j).to receive(:clear_filters).and_return(nil)

      expect(j).to receive(:add_filter).with(:priority, 1).ordered
      expect(j).to receive(:add_disjunction).ordered
      expect(j).to receive(:add_filter).with(:message, 'hello').ordered

      j.filter({ priority: 1 }, { message: 'hello' })

    end
  end

  describe '#add_conjunction' do
    it 'raises an exception if the call fails' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_add_conjunction)
        .and_return(-1)

      expect { j.add_conjunction }.to raise_error(Systemd::JournalError)
    end
  end

  describe '#add_disjunction' do
    it 'raises an exception if the call fails' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_add_disjunction)
        .and_return(-1)

      expect { j.add_disjunction }.to raise_error(Systemd::JournalError)
    end
  end

  describe '#clear_filters' do
    it 'flushes the matches' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_flush_matches)
        .and_return(nil)

      j.clear_filters
    end
  end

  describe '#disk_usage' do
    it 'returns the size used on disk' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_usage) do |_, size_ptr|
          size_ptr.write_size_t(12)
          0
        end

      expect(j.disk_usage).to eq(12)
    end

    it 'raises an error if the call fails' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_usage)
        .and_return(-1)

      expect { j.disk_usage }.to raise_error(Systemd::JournalError)
    end
  end

  describe '#data_threshold=' do
    it 'sets the data threshold' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_set_data_threshold)
        .with(anything, 0x1234)
        .and_return(0)

      j.data_threshold = 0x1234
    end

    it 'raises a JournalError on failure' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_set_data_threshold)
        .with(anything, 0x1234)
        .and_return(-1)

      expect do
        j.data_threshold = 0x1234
      end.to raise_error(Systemd::JournalError)
    end
  end

  describe '#data_threshold' do
    it 'gets the data threshold' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_data_threshold) do |_, size_ptr|
          size_ptr.write_size_t(0x1234)
          0
        end

      expect(j.data_threshold).to eq(0x1234)
    end

    it 'raises a JournalError on failure' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_data_threshold)
        .and_return(-3)

      expect { j.data_threshold }.to raise_error(Systemd::JournalError)
    end

  end

  describe '#cursor?' do
    it 'returns true if the current cursor is the provided value' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_test_cursor)
        .with(anything, '1234').and_return(1)

      expect(j.cursor?('1234')).to be true
    end

    it 'returns false otherwise' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_test_cursor)
        .with(anything, '1234')
        .and_return(0)

      expect(j.cursor?('1234')).to be false
    end

    it 'raises a JournalError on failure' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_test_cursor)
        .and_return(-3)

      expect { j.cursor?('123') }.to raise_error(Systemd::JournalError)
    end

  end

  describe '#cursor' do
    it 'returns the current cursor' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_cursor) do |_, out_ptr|
          # this memory will be manually freed. not setting autorelease to
          # false would cause a double free.
          str = FFI::MemoryPointer.from_string('5678')
          str.autorelease = false

          out_ptr.write_pointer(str)
          0
        end

      expect(j.cursor).to eq('5678')
    end

    it 'raises a JournalError on failure' do
      j = Systemd::Journal.new
      expect(Systemd::Journal::Native).to receive(:sd_journal_get_cursor)
        .and_return(-3)

      expect { j.cursor }.to raise_error(Systemd::JournalError)
    end

  end

end
