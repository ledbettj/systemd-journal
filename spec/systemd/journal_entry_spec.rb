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

end
