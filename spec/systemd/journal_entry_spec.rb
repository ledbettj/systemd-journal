require 'spec_helper'

describe Systemd::JournalEntry do
  subject do
    Systemd::JournalEntry.new(
      '_PID'      => '125',
      '_EXE'      => '/usr/bin/sshd',
      'PRIORITY'  => '4',
      'OBJECT_ID' => ':)'
    )
  end

  it 'allows enumerating entries' do
    expect { |b| subject.each(&b) }.to yield_successive_args(
      %w{_PID 125},
      %w{_EXE /usr/bin/sshd},
      %w{PRIORITY 4},
      %w{OBJECT_ID :)}
    )
  end

  it 'responds to field names as methods' do
    expect(subject._pid).to     eq('125')
    expect(subject.priority).to eq('4')
  end

  it 'doesnt overwrite existing methods' do
    expect(subject.object_id).to_not eq(':)')
  end

  it 'allows accessing via [string]' do
    expect(subject['OBJECT_ID']).to eq(':)')
  end

  it 'allows accessing via [symbol]' do
    expect(subject[:object_id]).to eq(':)')
  end

  it 'lists all fields it contains' do
    expect(subject.fields).to eq([:_pid, :_exe, :priority, :object_id])
  end

  it 'should not have a catalog' do
    expect(subject.catalog?).to be_false
  end

  it "doesn't throw NoMethod errors" do
    expect { subject.froobaz }.not_to raise_error
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
        expect(subject.catalog?).to be_true
      end
    end

    describe '#catalog' do
      it 'asks the journal for the message with our ID' do
        Systemd::Journal
          .should_receive(:catalog_for)
          .with('ab1fced28a0')
          .and_return('catalog')

        expect(subject.catalog).to eq('catalog')
      end

      it 'does field replacement by default' do
        Systemd::Journal
          .should_receive(:catalog_for)
          .with('ab1fced28a0')
          .and_return('catalog @_PID@ @PRIORITY@')

        expect(subject.catalog).to eq('catalog 125 4')
      end

      it 'skips field replacement if requested' do
        Systemd::Journal
          .should_receive(:catalog_for)
          .with('ab1fced28a0')
          .and_return('cat @_PID@ @PRIORITY@')

        expect(subject.catalog(replace: false)).to eq('cat @_PID@ @PRIORITY@')
      end
    end
  end

end
