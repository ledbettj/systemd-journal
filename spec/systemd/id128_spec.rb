require 'spec_helper'

describe Systemd::Id128 do

  describe 'boot_id' do
    it 'returns a properly formatted string representing the boot id' do
      expect(Systemd::Id128::Native).to receive(:sd_id128_get_boot) do |out|
        dummy = [0xa1, 0x0c] * 8
        out.write_array_of_uint8(dummy)
        0
      end
      expect(Systemd::Id128.boot_id).to eq('a10c' * 8)
    end
  end

  describe 'machine_id' do
    it 'returns a properly formatted string representing the machine id' do
      expect(Systemd::Id128::Native).to receive(:sd_id128_get_machine) do |out|
        dummy = [0xa1, 0x0c] * 8
        out.write_array_of_uint8(dummy)
        0
      end
      expect(Systemd::Id128.machine_id).to eq('a10c' * 8)
    end
  end

  describe 'random' do
    it 'returns a random hex string' do
      expect(Systemd::Id128::Native).to receive(:sd_id128_randomize) do |out|
        dummy = [0xa1, 0x0c] * 8
        out.write_array_of_uint8(dummy)
        0
      end
      expect(Systemd::Id128.random).to eq('a10c' * 8)
    end

  end

end
