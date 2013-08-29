require 'spec_helper'

describe Systemd::Journal do
  
  before(:each) do
    # don't actually make native API calls.
    dummy_open = ->(ptr, flags, path=nil) do
      dummy = FFI::MemoryPointer.new(:int, 1)
      ptr.write_pointer(dummy)
      0
    end

    Systemd::Journal::Native.stub(:sd_journal_open, &dummy_open)
    Systemd::Journal::Native.stub(:sd_journal_open_directory, &dummy_open)
    Systemd::Journal::Native.stub(:sd_journal_close).and_return(0)
  end

  describe 'initialize' do
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
    describe "move_#{direction}" do
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

    describe "move_#{direction}_skip" do
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
end
