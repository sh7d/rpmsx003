require 'bindata'

require 'pmsx003/checksum'
require 'pmsx003/commands'

module Pmsx003
  module Structs
    class Response < BinData::Record
      include ChecksumHelpers
      endian :big
      hide :header, :check_code
      skip do
        # HACK
        string read_length: 1, assert: Commands::HEADER[0]
        string read_length: 1, assert: Commands::HEADER[1]

        uint16 assert: 0x1C
      end
      struct :header do
        string :magic, read_length: 2
        uint16 :farme_len
      end
      struct :sensor_readings do
        uint16 :pm1concstan
        uint16 :pm25concstan
        uint16 :pm10concstan
        uint16 :pm1concatm
        uint16 :pm25concatm
        uint16 :pm10concatm
        uint16 :parnum03
        uint16 :parnum05
        uint16 :parnum1
        uint16 :parnum25
        uint16 :parnum5
        uint16 :parnum10
        uint16 :reserved
      end
      uint16 :check_code, assert: lambda {
        check_code == calc_ccode(
          header.to_binary_s + sensor_readings.to_binary_s
        )
      }
    end

    class Command < BinData::Record
      include ChecksumHelpers
      mandatory_parameters :command, :mode
      endian :big
      hide :header, :check_code

      string :header, read_length: 2, value: Commands::HEADER
      struct :settings do
        uint8 :_command, value: :command
        uint16 :_mode, value: lambda {
          return (mode ? 1 : 0) if [true, false].include?(mode)
          return (mode & 1) if mode.instance_of?(Integer)
        }
      end
      uint16 :check_code, value: -> { calc_ccode(header.b + settings.to_binary_s) }
    end
  end
end
