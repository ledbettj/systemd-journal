require 'spec_helper'

describe Systemd::Journal do

  describe '#initialize' do
    it 'opens a directory if a path is passed' do
      Systemd::Journal::Native.should_receive(:sd_journal_open_directory)
      Systemd::Journal::Native.should_not_receive(:sd_journal_open)
      Systemd::Journal.new(path: '/path/to/journal')
    end

    it 'accepts flags as an argument' do
      Systemd::Journal::Native.should_receive(:sd_journal_open).with(anything, 1234)
      Systemd::Journal.new(flags: 1234)
    end

    it 'raises a Journal Error if a native call fails' do
      Systemd::Journal::Native.should_receive(:sd_journal_open).and_return(-1)
      expect {
        Systemd::Journal.new
      }.to raise_error(Systemd::JournalError)
    end
  end

  ['next', 'previous'].each do |direction|
    describe "#move_#{direction}" do
      it 'returns true on a successful move' do
        j = Systemd::Journal.new
        Systemd::Journal::Native.should_receive(:"sd_journal_#{direction}").and_return(1)
        j.send(:"move_#{direction}").should eq(true)
      end

      it 'returns false on EOF' do
        j = Systemd::Journal.new
        Systemd::Journal::Native.should_receive(:"sd_journal_#{direction}").and_return(0)
        j.send(:"move_#{direction}").should eq(false)
      end

      it 'raises an exception on failure' do
        j = Systemd::Journal.new
        Systemd::Journal::Native.should_receive(:"sd_journal_#{direction}").and_return(-1)
        expect {
          j.send(:"move_#{direction}")
        }.to raise_error(Systemd::JournalError)
      end
    end

    describe "#move_#{direction}_skip" do
      it 'returns the number of records moved by' do
        Systemd::Journal::Native.should_receive(:"sd_journal_#{direction}_skip").
          with(anything, 10).and_return(10)

        Systemd::Journal.new.send(:"move_#{direction}_skip", 10).should eq(10)
      end

      it 'raises an exception on failure' do
        Systemd::Journal::Native.should_receive(:"sd_journal_#{direction}_skip").
          with(anything, 10).and_return(-1)

        j = Systemd::Journal.new

        expect { j.send(:"move_#{direction}_skip", 10) }.to raise_error(Systemd::JournalError)
      end
    end
  end

  describe '#each' do
    it 'should reposition to the head of the journal' do
      j = Systemd::Journal.new
      j.should_receive(:seek).with(:head).and_return(0)
      j.stub(:move_next).and_return(nil)
      j.each{|e| nil }
    end

    it 'should return an enumerator if no block is given' do
      j = Systemd::Journal.new
      j.each.class.should eq(Enumerator)
    end

    it 'should return each entry in the journal' do
      entries = [{'_PID' => 1}, {'_PID' => 2}]
      entry   = nil

      j = Systemd::Journal.new
      j.stub(:seek).and_return(0)
      j.stub(:current_entry) { entry }
      j.stub(:move_next)     { entry = entries.shift }

      j.map{|e| e['_PID'] }.should eq([1, 2])
    end

  end

  describe '#seek' do
    it 'moves to the first entry of the file' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_seek_head).and_return(0)
      j.seek(:head).should eq(true)
    end

    it 'moves to the last entry of the file' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_seek_tail).and_return(0)
      j.seek(:tail).should eq(true)
    end

    it 'seeks based on time when a time is provided' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_seek_realtime_usec).and_return(0)
      j.seek(Time.now).should eq(true)
    end

    it 'seeks based on a cursor when a string is provided' do
      j = Systemd::Journal.new

      Systemd::Journal::Native.should_receive(:sd_journal_seek_cursor).
        with(anything, "123").and_return(0)

      j.seek("123")
    end

    it 'throws an exception if it doesnt understand the type' do
      j = Systemd::Journal.new
      expect { j.seek(Object.new) }.to raise_error(ArgumentError)
    end
  end

  describe '#read_field' do
    it 'raises an exception if the call fails' do
      Systemd::Journal::Native.should_receive(:sd_journal_get_data).and_return(-1)

      j = Systemd::Journal.new
      expect{ j.read_field(:message) }.to raise_error(Systemd::JournalError)
    end

    it 'parses the returned value correctly.' do
      j = Systemd::Journal.new

      Systemd::Journal::Native.should_receive(:sd_journal_get_data) do |ptr, field, out_ptr, len_ptr|
        dummy = "MESSAGE=hello world"
        out_ptr.write_pointer(FFI::MemoryPointer.from_string(dummy))
        len_ptr.write_size_t(dummy.size)
        0
      end

      j.read_field(:message).should eq("hello world")
    end
  end

  describe '#current_entry' do
    before(:each) do
      Systemd::Journal::Native.should_receive(:sd_journal_restart_data).and_return(nil)
    end

    it 'raises an exception if the call fails' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_enumerate_data).and_return(-1)
      expect { j.current_entry }.to raise_error(Systemd::JournalError)
    end

    it 'returns the correct data' do
      j = Systemd::Journal.new
      results = ['_PID=100', 'MESSAGE=hello world']

      Systemd::Journal::Native.should_receive(:sd_journal_enumerate_data).exactly(3).times do |ptr, out_ptr, len_ptr|
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

      entry._pid.should     eq('100')
      entry.message.should eq('hello world')

    end
  end

  describe '#query_unique' do
    before(:each) do
      Systemd::Journal::Native.should_receive(:sd_journal_restart_unique).and_return(nil)
    end

    it 'raises an exception if the call fails' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_query_unique).and_return(-1)
      expect { j.query_unique(:_pid) }.to raise_error(Systemd::JournalError)
    end

    it 'raises an exception if the call fails (2)' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_query_unique).and_return(0)
      Systemd::Journal::Native.should_receive(:sd_journal_enumerate_unique).and_return(-1)
      expect { j.query_unique(:_pid) }.to raise_error(Systemd::JournalError)
    end

    it 'returns the correct data' do
      j = Systemd::Journal.new
      results = ['_PID=100', '_PID=200', '_PID=300']

      Systemd::Journal::Native.should_receive(:sd_journal_query_unique).and_return(0)

      Systemd::Journal::Native.should_receive(:sd_journal_enumerate_unique).exactly(4).times do |ptr, out_ptr, len_ptr|
        if results.any?
          x = results.shift
          out_ptr.write_pointer(FFI::MemoryPointer.from_string(x))
          len_ptr.write_size_t(x.length)
          1
        else
          0
        end
      end

      j.query_unique(:_pid).should eq(['100', '200', '300'])
    end

  end

  describe '#wait' do
    it 'raises an exception if the call fails' do
      Systemd::Journal::Native.should_receive(:sd_journal_wait).and_return(-1)

      j = Systemd::Journal.new
      expect{ j.wait(100) }.to raise_error(Systemd::JournalError)
    end

    it 'returns the reason we were woken up' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_wait).and_return(:append)
      j.wait(100).should eq(:append)
    end

    it 'returns nil if we reached the timeout.' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_wait).and_return(:nop)
      j.wait(100).should eq(nil)
    end
  end

  describe '#add_match' do
    it 'raises an exception if the call fails' do
      Systemd::Journal::Native.should_receive(:sd_journal_add_match).and_return(-1)

      j = Systemd::Journal.new
      expect{ j.add_match(:message, "test") }.to raise_error(Systemd::JournalError)
    end

    it 'formats the arguments appropriately' do
      Systemd::Journal::Native.should_receive(:sd_journal_add_match).
        with(anything, "MESSAGE=test", "MESSAGE=test".length).
        and_return(0)

      Systemd::Journal.new.add_match(:message, "test")
    end
  end

  describe '#add_conjunction' do
    it 'raises an exception if the call fails' do
      Systemd::Journal::Native.should_receive(:sd_journal_add_conjunction).and_return(-1)

      j = Systemd::Journal.new
      expect{ j.add_conjunction }.to raise_error(Systemd::JournalError)
    end
  end

  describe '#add_disjunction' do
    it 'raises an exception if the call fails' do
      Systemd::Journal::Native.should_receive(:sd_journal_add_disjunction).and_return(-1)

      j = Systemd::Journal.new
      expect{ j.add_disjunction }.to raise_error(Systemd::JournalError)
    end
  end

  describe '#clear_matches' do
    it 'flushes the matches' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_flush_matches).and_return(nil)
      j.clear_matches
    end
  end

  describe '#disk_usage' do
    it 'returns the size used on disk' do
      Systemd::Journal::Native.should_receive(:sd_journal_get_usage) do |ptr, size_ptr|
        size_ptr.write_size_t(12)
        0
      end
      j = Systemd::Journal.new
      j.disk_usage.should eq(12)
    end

    it 'raises an error if the call fails' do
      Systemd::Journal::Native.should_receive(:sd_journal_get_usage).and_return(-1)
      j = Systemd::Journal.new
      expect { j.disk_usage }.to raise_error(Systemd::JournalError)
    end
  end

  describe '#data_threshold=' do
    it 'sets the data threshold' do
      j = Systemd::Journal.new

      Systemd::Journal::Native.should_receive(:sd_journal_set_data_threshold).
        with(anything, 0x1234).and_return(0)

      j.data_threshold = 0x1234
    end
  end

  describe '#data_threshold' do
    it 'gets the data threshold' do
      j = Systemd::Journal.new

      Systemd::Journal::Native.should_receive(:sd_journal_get_data_threshold) do |ptr, size_ptr|
        size_ptr.write_size_t(0x1234)
        0
      end
      j.data_threshold.should eq(0x1234)
    end
  end

  describe '#cursor?' do
    it 'returns true if the current cursor is the provided value' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_test_cursor).
        with(anything, "1234").and_return(1)

      j.cursor?("1234").should eq(true)
    end

    it 'returns false otherwise' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_test_cursor).
        with(anything, "1234").and_return(0)

      j.cursor?("1234").should eq(false)
    end
  end

  describe '#cursor' do
    it 'returns the current cursor' do
      j = Systemd::Journal.new
      Systemd::Journal::Native.should_receive(:sd_journal_get_cursor) do |ptr, out_ptr|
        out_ptr.write_pointer(FFI::MemoryPointer.from_string("5678"))
        0
      end
      j.cursor.should eq("5678")
    end
  end

end
