require 'rspec'
require 'simplecov'

SimpleCov.start do
  add_filter '.bundle/'
end
require 'systemd/journal'

RSpec.configure do |config|
  config.before(:each) do

    # Stub open and close calls
    dummy_open = ->(ptr, _flags, _path = nil) do
      ptr.write_pointer(nil)
      0
    end

    ['', '_directory', '_files', '_container'].each do |suffix|
      allow(Systemd::Journal::Native).to receive(:"sd_journal_open#{suffix}", &dummy_open)
    end
    allow(Systemd::Journal::Native).to receive(:sd_journal_close).and_return(0)

    # Raise an exception if any native calls are actually called
    native_calls = Systemd::Journal::Native.methods.select do |m|
      m.to_s.start_with?('sd_')
    end

    native_calls -= [
      :sd_journal_open, :sd_journal_open_directory, :sd_journal_close,
      :sd_journal_open_files, :sd_journal_open_container
    ]

    build_err_proc = ->(method_name) do
      return ->(*params) do
        raise RuntimeError.new("#{method_name} called without being stubbed.")
      end
    end

    native_calls.each do |meth|
      allow(Systemd::Journal::Native).to receive(meth, &build_err_proc.call(meth))
    end
  end
end
