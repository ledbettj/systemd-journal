require 'rspec'
require 'simplecov'

SimpleCov.start
require 'systemd/journal'

RSpec.configure do |config|
  config.before(:each) do

    # Stub open and close calls
    dummy_open = ->(ptr, flags, path=nil) do
      ptr.write_pointer(nil)
      0
    end

    Systemd::Journal::Native.stub(:sd_journal_open, &dummy_open)
    Systemd::Journal::Native.stub(:sd_journal_open_directory, &dummy_open)
    Systemd::Journal::Native.stub(:sd_journal_close).and_return(0)

    # Raise an exception if any native calls are actually called
    native_calls = Systemd::Journal::Native.methods.select do |m|
      m.to_s.start_with?("sd_")
    end

    native_calls -= [
      :sd_journal_open, :sd_journal_open_directory, :sd_journal_close
    ]

    build_err_proc = ->(method_name) do
      return ->(*params) do
        raise RuntimeError.new("#{method_name} called without being stubbed.")
      end
    end

    native_calls.each do |meth|
      Systemd::Journal::Native.stub(meth, &build_err_proc.call(meth))
    end
  end
end
