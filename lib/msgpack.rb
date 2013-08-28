# encoding: utf-8

module MessagePack
  def self.pack(obj)

  end

  def self.unpack(bytes)
    Decoder.new(bytes).next
  end

  class Decoder
    def initialize(bytes)
      @bytes = bytes
      @offset = 0
    end

    def next
      consume_next
    end

    private

    FLOAT_FMT = 'g'.freeze
    DOUBLE_FMT = 'G'.freeze

    def consume_byte
      b = @bytes.getbyte(@offset)
      @offset += 1
      b
    end

    def consume_int16
      (consume_byte << 8) | consume_byte
    end

    def consume_int32
      (consume_byte << 24) | (consume_byte << 16) | (consume_byte << 8) | consume_byte
    end

    def consume_int64
      n  = (consume_byte << 56)
      n |= (consume_byte << 48)
      n |= (consume_byte << 40)
      n |= (consume_byte << 32)
      n |= (consume_byte << 24)
      n |= (consume_byte << 16)
      n |= (consume_byte << 8)
      n |=  consume_byte
      n
    end

    def consume_float
      f = @bytes[@offset, 4].unpack(FLOAT_FMT).first
      @offset += 4
      f
    end

    def consume_double
      d = @bytes[@offset, 8].unpack(DOUBLE_FMT).first
      @offset += 8
      d
    end

    def consume_string(size)
      s = @bytes[@offset, size]
      s.force_encoding(Encoding::UTF_8)
      @offset += size
      s
    end

    def consume_binary(size)
      s = @bytes[@offset, size]
      s.force_encoding(Encoding::BINARY)
      @offset += size
      s
    end

    def consume_array(size)
      Array.new(size) { consume_next }
    end

    def consume_next
      b = consume_byte
      if b == 0xc0
        nil
      elsif b == 0xc3
        true
      elsif b == 0xc2
        false
      elsif b <= 0b01111111
        b
      elsif b & 0b11100000 == 0b11100000
        b - 0x100
      elsif b == 0xcc
        consume_byte
      elsif b == 0xd0
        consume_byte - 0x100
      elsif b == 0xcd
        consume_int16
      elsif b == 0xd1
        consume_int16 - 0x10000
      elsif b == 0xce
        consume_int32
      elsif b == 0xd2
        consume_int32 - 0x100000000
      elsif b == 0xcf
        consume_int64
      elsif b == 0xd3
        consume_int64 - 0x10000000000000000
      elsif b == 0xca
        consume_float
      elsif b == 0xcb
        consume_double
      elsif b & 0b11100000 == 0b10100000
        size = b & 0b00011111
        consume_string(size)
      elsif b == 0xd9
        size = consume_byte
        consume_string(size)
      elsif b == 0xc4
        size = consume_byte
        consume_binary(size)
      elsif b == 0xda
        size = consume_int16
        consume_string(size)
      elsif b == 0xc5
        size = consume_int16
        consume_binary(size)
      elsif b == 0xdb
        size = consume_int32
        consume_string(size)
      elsif b == 0xc6
        size = consume_int32
        consume_binary(size)
      elsif b & 0b11110000 == 0b10010000
        size = b & 0b00001111
        consume_array(size)
      elsif b == 0xdc
        size = consume_int16
        consume_array(size)
      elsif b == 0xdd
        size = consume_int32
        consume_array(size)
      elsif b & 0b11110000 == 0b10000000
        size = b & 0b00001111
        Hash[*consume_array(size * 2)]
      elsif b == 0xde
        size = consume_int16
        Hash[*consume_array(size * 2)]
      elsif b == 0xdf
        size = consume_int32
        Hash[*consume_array(size * 2)]
      end
    end
  end
end