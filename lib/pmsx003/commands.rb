# frozen_string_literal: true

module Pmsx003
  module Commands
    HEADER = 'BM'.b
    READ_PASSIVE = 0xE2
    module Change
      MODE = 0xE1
      SLEEP = 0xE4
    end
  end
end
