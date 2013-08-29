require 'spec_helper'

describe Systemd::Journal do

  
  before(:each) do
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
end
