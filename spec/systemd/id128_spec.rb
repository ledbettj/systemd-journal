require 'spec_helper'

describe Systemd::Id128 do

  describe 'boot_id' do
    it 'returns a properly formatted string representing the boot id' do
      Systemd::Id128::Native.should_receive(:sd_id128_get_boot) do |out|
        dummy = [0xa1, 0x0c] * 8
        out.write_array_of_uint8(dummy)
        0
      end
      Systemd::Id128.boot_id.should eq("a10c" * 8)
    end
  end

  describe 'machine_id' do
    it 'returns a properly formatted string representing the machine id' do
      Systemd::Id128::Native.should_receive(:sd_id128_get_machine) do |out|
        dummy = [0xa1, 0x0c] * 8
        out.write_array_of_uint8(dummy)
        0
      end
      Systemd::Id128.machine_id.should eq("a10c" * 8)
    end
  end

  describe 'random' do
    it 'returns a random hex string' do
      Systemd::Id128::Native.should_receive(:sd_id128_randomize) do |out|
        dummy = [0xa1, 0x0c] * 8
        out.write_array_of_uint8(dummy)
        0
      end
      Systemd::Id128.random.should eq("a10c" * 8)
    end    

  end
  
end
