# encoding: binary

require 'benchmark'
require 'msgpack'


BYTES = "\x85\xa3foo\xa3bar\x03\xa5three\xa4four\x04\xa1x\x91\xa1y\xa1a\xa1b"


Benchmark.bmbm(10) do |x|
  x.report('msgpack') do
    1_000_000.times { MessagePack.unpack(BYTES) }
  end
end