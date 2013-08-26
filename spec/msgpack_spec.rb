# encoding: ascii-8bit

require 'spec_helper'


describe MessagePack do
  tests = {
    'constant values' => [
      ['true', true, "\xc3"],
      ['false', false, "\xc2"],
      ['nil', nil, "\xc0"],
    ],
    'numbers' => [
      ['zero', 0, "\x00"],
      ['127', 0x7f, "\x7f"],
      ['128', 0x80, "\xcc\x80"],
      ['256', 0x100, "\xcd\x01\x00"],
      ['23435345', 0x01659851, "\xCE\x01\x65\x98\x51"],
      ['2342347938475324', 0x0008525a60d02d3c, "\xcf\x00\x08\x52\x5a\x60\xd0\x2d\x3c"],
      ['-1', -1, "\xff"],
      ['-33', -33, "\xd0\xdf"],
      ['-129', -129, "\xd1\xff\x7f"],
      ['-8444910', -8444910, "\xd2\xff\x7f\x24\x12"],
      ['-41957882392009710', -41957882392009710, "\xd3\xff\x6a\xef\x87\x3c\x7f\x24\x12"],
      ['small integers', 42, "*"],
      ['medium integers', 333, "\xcd\x01M"],
      ['large integers', 2**31 - 1, "\xce\x7f\xff\xff\xff"],
      ['huge integers', 2**64 - 1, "\xcf\xff\xff\xff\xff\xff\xff\xff\xff"],
      ['negative integers', -1, "\xff"],
      ['1.0', 1.0, "\xcb\x3f\xf0\x00\x00\x00\x00\x00\x00"],
      ['small floats', 3.14, "\xca@H\xf5\xc3"],
      ['big floats', Math::PI * 1_000_000_000_000_000_000, "\xcbC\xc5\xcc\x96\xef\xd1\x19%"],
      ['negative floats', -2.1, "\xcb\xc0\x00\xcc\xcc\xcc\xcc\xcc\xcd"],
    ],
    'strings' => [
      ['strings', 'hello world', "\xabhello world"],
      ['empty strings', '', "\xa0"],
      ['medium strings', 'x' * 0xdd, "\xd9\xdd#{'x' * 0xdd}"],
      ['big strings', 'x' * 0xdddd, "\xda\xdd\xdd#{'x' * 0xdddd}"],
      ['huge strings', 'x' * 0x0000dddd, "\xdb\x00\x00\xdd\xdd#{'x' * 0x0000dddd}"],
    ],
    'binaries' => [
      ['medium binary', "\a" * 0x5, "\xc4\x05#{"\a" * 0x5}"],
      ['big binary', "\a" * 0x100, "\xc5\x01\x00#{"\a" * 0x100}"],
      ['huge binary', "\a" * 0x10000, "\xc6\x00\x01\x00\x00#{"\a" * 0x10000}"],
    ],
    'arrays' => [
      ['empty arrays', [], "\x90"],
      ['small arrays', [1, 2], "\x92\x01\x02"],
      ['medium arrays', [false] * 0x111, "\xdc\x01\x11#{"\xc2" * 0x111}"],
      ['big arrays', [false] * 0x11111, "\xdd\x00\x01\x11\x11#{"\xc2" * 0x11111}"],
      ['arrays with strings', ["hello", "world"], "\x92\xa5hello\xa5world"],
      ['arrays with mixed values', ["hello", "world", 42], "\x93\xa5hello\xa5world*"],
      ['arrays of arrays', [[[[1, 2], 3], 4]], "\x91\x92\x92\x92\x01\x02\x03\x04"],
    ],
    'hashes' => [
      ['empty hashes', {}, "\x80"],
      ['small hashes', {'foo' => 'bar'}, "\x81\xa3foo\xa3bar"],
      ['medium hashes', {'foo' => 'bar'}, "\xde\x00\x01\xa3foo\xa3bar"],
      ['big hashes', {'foo' => 'bar'}, "\xdf\x00\x00\x00\x01\xa3foo\xa3bar"],
      ['hashes with mixed keys and values', {'foo' => 'bar', 3 => 'three', 'four' => 4, 'x' => ['y'], 'a' => 'b'}, "\x85\xa3foo\xa3bar\x03\xa5three\xa4four\x04\xa1x\x91\xa1y\xa1a\xa1b"],
      ['hashes of hashes', {{'x' => {'y' => 'z'}} => 's'}, "\x81\x81\xa1x\x81\xa1y\xa1z\xa1s"],
      ['hashes with nils', {'foo' => nil}, "\x81\xa3foo\xc0"]
    ]
  }

  tests.each do |ctx, its|
    context("with #{ctx}") do
      its.each do |desc, unpacked, packed|
        it("encodes #{desc}") do
          MessagePack.pack(unpacked).should eql(packed), "expected #{unpacked.inspect[0, 100]} to equal #{packed.inspect[0, 100]}"
        end
      
        it "decodes #{desc}" do
          decoded = MessagePack.unpack(packed)
          if packed.getbyte(0) == 0xca
            decoded.should be_within(0.00001).of(unpacked)
          else
            decoded.should eql(unpacked), "expected #{decoded.inspect[0, 100]} to equal #{unpacked.inspect[0, 100]}"
            if ctx == 'strings'
              decoded.encoding.should eql(Encoding::UTF_8)
            elsif ctx == 'binaries'
              decoded.encoding.should eql(Encoding::BINARY)
            end
          end
        end
      end
    end
  end
  
  context 'with symbols' do
    it 'encodes symbols as strings' do
      MessagePack.pack(:symbol).should == "\xA6symbol"
    end
  end

  context 'with other things' do
    it 'raises an error on #pack with an unsupported type' do
      expect { MessagePack.pack(self) }.to raise_error(ArgumentError, /^Cannot pack type:/)
    end
    
    it 'rasies an error on #unpack with garbage' do
      pending
      expect { MessagePack.unpack('asdka;sd') }.to raise_error(MessagePack::UnpackError)
    end
  end

  context 'extensions' do
    it 'can unpack hashes with symbolized keys' do
      packed = MessagePack.pack({'hello' => 'world', 'nested' => ['object', {'structure' => true}]})
      unpacked = MessagePack.unpack(packed, symbolize_keys: true)
      unpacked.should == {:hello => 'world', :nested => ['object', {:structure => true}]}
    end

    it 'can unpack strings with a specified encoding', :encodings do
      packed = MessagePack.pack({'hello' => 'world'})
      unpacked = MessagePack.unpack(packed, encoding: Encoding::UTF_8)
      unpacked['hello'].encoding.should == Encoding::UTF_8
    end
  end
end