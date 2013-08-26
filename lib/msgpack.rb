# encoding: utf-8

module MessagePack
  def self.pack(obj)

  end

  def self.unpack(bytes)
    decode(bytes, 0).first
  end

  module Decoding
    FLOAT_FMT = 'g'.freeze
    DOUBLE_FMT = 'G'.freeze

    def decode_int16(bytes, offset)
      (bytes.getbyte(offset) << 8) | bytes.getbyte(offset + 1)
    end

    def decode_int32(bytes, offset)
      (bytes.getbyte(offset) << 24) | (bytes.getbyte(offset + 1) << 16) | (bytes.getbyte(offset + 2) << 8) | bytes.getbyte(offset + 3)
    end

    def decode_int64(bytes, offset)
      x  = (bytes.getbyte(offset + 0) << 56)
      x |= (bytes.getbyte(offset + 1) << 48)
      x |= (bytes.getbyte(offset + 2) << 40)
      x |= (bytes.getbyte(offset + 3) << 32)
      x |= (bytes.getbyte(offset + 4) << 24)
      x |= (bytes.getbyte(offset + 5) << 16)
      x |= (bytes.getbyte(offset + 6) << 8)
      x |=  bytes.getbyte(offset + 7)
      x
    end

    def decode_array(bytes, offset, size, bytes_consumed)
      array = Array.new(size)
      size.times do |i|
        e, bc = decode(bytes, offset + bytes_consumed)
        array[i] = e
        bytes_consumed += bc
      end
      return array, bytes_consumed
    end

    def decode(bytes, offset)
      b = bytes.getbyte(offset)
      if b == 0xc0
        return nil, 1
      elsif b == 0xc3
        return true, 1
      elsif b == 0xc2
        return false, 1
      elsif b <= 0b01111111
        return b, 1
      elsif b & 0b11100000 == 0b11100000
        return b - 0x100, 1
      elsif b == 0xcc
        return bytes.getbyte(offset + 1), 2
      elsif b == 0xd0
        return bytes.getbyte(offset + 1) - 0x100, 2
      elsif b == 0xcd
        return decode_int16(bytes, offset + 1), 3
      elsif b == 0xd1
        return (decode_int16(bytes, offset + 1)) - 0x10000, 3
      elsif b == 0xce
        return decode_int32(bytes, offset + 1), 5
      elsif b == 0xd2
        return decode_int32(bytes, offset + 1) - 0x100000000, 5
      elsif b == 0xcf
        return decode_int64(bytes, offset + 1), 9
      elsif b == 0xd3
        return decode_int64(bytes, offset + 1) - 0x10000000000000000, 9
      elsif b == 0xca
        return bytes[offset + 1, 4].unpack(FLOAT_FMT).first, 5
      elsif b == 0xcb
        return bytes[offset + 1, 8].unpack(DOUBLE_FMT).first, 9
      elsif b & 0b11100000 == 0b10100000
        size = b & 0b00011111
        return bytes[offset + 1, size].force_encoding(Encoding::UTF_8), size + 1
      elsif b == 0xd9
        size = bytes.getbyte(offset + 1)
        return bytes[offset + 2, size].force_encoding(Encoding::UTF_8), size + 2
      elsif b == 0xc4
        size = bytes.getbyte(offset + 1)
        return bytes[offset + 2, size].force_encoding(Encoding::BINARY), size + 2
      elsif b == 0xda
        size = decode_int16(bytes, offset + 1)
        return bytes[offset + 3, size].force_encoding(Encoding::UTF_8), size + 3
      elsif b == 0xc5
        size = decode_int16(bytes, offset + 1)
        return bytes[offset + 3, size].force_encoding(Encoding::BINARY), size + 3
      elsif b == 0xdb
        size = decode_int32(bytes, offset + 1)
        return bytes[offset + 5, size].force_encoding(Encoding::UTF_8), size + 5
      elsif b == 0xc6
        size = decode_int32(bytes, offset + 1)
        return bytes[offset + 5, size].force_encoding(Encoding::BINARY), size + 5
      elsif b & 0b11110000 == 0b10010000
        size = b & 0b00001111
        return decode_array(bytes, offset, size, 1)
      elsif b == 0xdc
        size = decode_int16(bytes, offset + 1)
        return decode_array(bytes, offset + 2, size, 1)
      elsif b == 0xdd
        size = decode_int32(bytes, offset + 1)
        return decode_array(bytes, offset + 4, size, 1)
      elsif b & 0b11110000 == 0b10000000
        size = b & 0b00001111
        r = decode_array(bytes, offset, size * 2, 1)
        r[0] = Hash[*r[0]]
        return r
      elsif b == 0xde
        size = decode_int16(bytes, offset + 1)
        r = decode_array(bytes, offset + 2, size * 2, 1)
        r[0] = Hash[*r[0]]
        return r
      elsif b == 0xdf
        size = decode_int32(bytes, offset + 1)
        r = decode_array(bytes, offset + 4, size * 2, 1)
        r[0] = Hash[*r[0]]
        return r
      end
    end
  end

  extend Decoding
end