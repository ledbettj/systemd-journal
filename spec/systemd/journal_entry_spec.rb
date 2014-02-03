require 'spec_helper'

describe Systemd::JournalEntry do
  subject do
    Systemd::JournalEntry.new(
      '_PID'     => '125',
      '_EXE'     => '/usr/bin/sshd',
      'PRIORITY' => '4',
      'OBJECT_ID'=> ':)'
    )
  end

  it 'allows enumerating entries' do
    expect{ |b| subject.each(&b) }.to yield_successive_args(
      ['_PID', '125'],
      ['_EXE', '/usr/bin/sshd'],
      ['PRIORITY', '4'],
      ['OBJECT_ID', ':)']
    )
  end

  it 'responds to field names as methods' do
    subject._pid.should     eq('125')
    subject.priority.should eq('4')
  end

  it 'doesnt overwrite existing methods' do
    subject.object_id.should_not eq(':)')
  end

  it 'allows accessing via [string]' do
    subject['OBJECT_ID'].should eq(':)')
  end

  it 'allows accessing via [symbol]' do
    subject[:object_id].should eq(':)')
  end

  it 'lists all fields it contains' do
    subject.fields.should eq([:_pid, :_exe, :priority, :object_id])
  end

  it 'should not have a catalog' do
    subject.catalog?.should eq(false)
  end

  context 'with catalogs' do
    subject do
      Systemd::JournalEntry.new(
        '_PID'       => '125',
        '_EXE'       => '/usr/bin/sshd',
        'PRIORITY'   => '4',
        'MESSAGE_ID' => 'ab1fced28a0'
      )
    end

    describe '#catalog?' do
      it 'returns true if the entry has a message ID' do
        subject.catalog?.should eq(true)
      end
    end

    describe '#catalog' do

      it 'asks the journal for the message with our ID' do
        Systemd::Journal.should_receive(:catalog_for).with('ab1fced28a0').and_return('catalog')
        subject.catalog.should eq('catalog')
      end

      it 'does field replacement by default' do
        Systemd::Journal.should_receive(:catalog_for).with('ab1fced28a0').and_return('catalog @_PID@ @PRIORITY@')
        subject.catalog.should eq('catalog 125 4')
      end

      it 'skips field replacement if requested' do
        Systemd::Journal.should_receive(:catalog_for).with('ab1fced28a0').and_return('catalog @_PID@ @PRIORITY@')
        subject.catalog(replace: false).should eq('catalog @_PID@ @PRIORITY@')
      end
    end
  end

end
