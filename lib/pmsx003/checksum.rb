module Pmsx003
  module ChecksumHelpers
    private

    def calc_ccode(bytestream)
      bytestream.b.bytes.inject(:+) & 65535
    end
  end
end
