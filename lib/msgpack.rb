# encoding: utf-8

module MessagePack
  def self.pack(obj)
  end

  def self.unpack(bytes)
    decode(bytes, 0).first
  end

  private

  def self.decode(bytes, offset)
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
      return (bytes.getbyte(offset + 1) << 8) | bytes.getbyte(offset + 2), 3
    elsif b == 0xd1
      return ((bytes.getbyte(offset + 1) << 8) | bytes.getbyte(offset + 2)) - 0x10000, 3
    elsif b == 0xce
      x  = (bytes.getbyte(offset + 1) << 24)
      x |= (bytes.getbyte(offset + 2) << 16)
      x |= (bytes.getbyte(offset + 3) << 8)
      x |=  bytes.getbyte(offset + 4)
      return x, 5
    elsif b == 0xd2
      x  = (bytes.getbyte(offset + 1) << 24)
      x |= (bytes.getbyte(offset + 2) << 16)
      x |= (bytes.getbyte(offset + 3) << 8)
      x |=  bytes.getbyte(offset + 4)
      return x - 0x100000000, 5
    elsif b == 0xcf
      x  = (bytes.getbyte(offset + 1) << 56)
      x |= (bytes.getbyte(offset + 2) << 48)
      x |= (bytes.getbyte(offset + 3) << 40)
      x |= (bytes.getbyte(offset + 4) << 32)
      x |= (bytes.getbyte(offset + 5) << 24)
      x |= (bytes.getbyte(offset + 6) << 16)
      x |= (bytes.getbyte(offset + 7) << 8)
      x |=  bytes.getbyte(offset + 8)
      return x, 9
    elsif b == 0xd3
      x  = (bytes.getbyte(offset + 1) << 56)
      x |= (bytes.getbyte(offset + 2) << 48)
      x |= (bytes.getbyte(offset + 3) << 40)
      x |= (bytes.getbyte(offset + 4) << 32)
      x |= (bytes.getbyte(offset + 5) << 24)
      x |= (bytes.getbyte(offset + 6) << 16)
      x |= (bytes.getbyte(offset + 7) << 8)
      x |=  bytes.getbyte(offset + 8)
      return x - 0x10000000000000000, 9
    elsif b == 0xca
      return bytes[offset + 1, 4].unpack('g').first, 5
    elsif b == 0xcb
      return bytes[offset + 1, 8].unpack('G').first, 9
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
      size = (bytes.getbyte(offset + 1) << 8) | bytes.getbyte(offset + 2)
      return bytes[offset + 3, size].force_encoding(Encoding::UTF_8), size + 3
    elsif b == 0xc5
      size = (bytes.getbyte(offset + 1) << 8) | bytes.getbyte(offset + 2)
      return bytes[offset + 3, size].force_encoding(Encoding::BINARY), size + 3
    elsif b == 0xdb
      size = (bytes.getbyte(offset + 1) << 24) | (bytes.getbyte(offset + 2) << 16) | (bytes.getbyte(offset + 3) << 8) | bytes.getbyte(offset + 4)
      return bytes[offset + 5, size].force_encoding(Encoding::UTF_8), size + 5
    elsif b == 0xc6
      size = (bytes.getbyte(offset + 1) << 24) | (bytes.getbyte(offset + 2) << 16) | (bytes.getbyte(offset + 3) << 8) | bytes.getbyte(offset + 4)
      return bytes[offset + 5, size].force_encoding(Encoding::BINARY), size + 5
    elsif b & 0b11110000 == 0b10010000
      size = b & 0b00001111
      list = Array.new(size)
      bytes_consumed = 1
      size.times do |i|
        e, bc = decode(bytes, offset + bytes_consumed)
        list[i] = e
        bytes_consumed += bc
      end
      return list, bytes_consumed
    elsif b == 0xdc
      size = (bytes.getbyte(offset + 1) << 8) | bytes.getbyte(offset + 2)
      list = Array.new(size)
      bytes_consumed = 3
      size.times do |i|
        e, bc = decode(bytes, offset + bytes_consumed)
        list[i] = e
        bytes_consumed += bc
      end
      return list, bytes_consumed
    elsif b == 0xdd
      size = (bytes.getbyte(offset + 1) << 24) | (bytes.getbyte(offset + 2) << 16) | (bytes.getbyte(offset + 3) << 8) | bytes.getbyte(offset + 4)
      list = Array.new(size)
      bytes_consumed = 5
      size.times do |i|
        e, bc = decode(bytes, offset + bytes_consumed)
        list[i] = e
        bytes_consumed += bc
      end
      return list, bytes_consumed
    elsif b & 0b11110000 == 0b10000000
      size = b & 0b00001111
      hash = {}
      bytes_consumed = 1
      size.times do
        key, bc = decode(bytes, offset + bytes_consumed)
        bytes_consumed += bc
        value, bc = decode(bytes, offset + bytes_consumed)
        bytes_consumed += bc
        hash[key] = value
      end
      return hash, bytes_consumed
    elsif b == 0xde
      size = (bytes.getbyte(offset + 1) << 8) | bytes.getbyte(offset + 2)
      hash = {}
      bytes_consumed = 3
      size.times do
        key, bc = decode(bytes, offset + bytes_consumed)
        bytes_consumed += bc
        value, bc = decode(bytes, offset + bytes_consumed)
        bytes_consumed += bc
        hash[key] = value
      end
      return hash, bytes_consumed
    elsif b == 0xdf
      size = (bytes.getbyte(offset + 1) << 24) | (bytes.getbyte(offset + 2) << 16) | (bytes.getbyte(offset + 3) << 8) | bytes.getbyte(offset + 4)
      hash = {}
      bytes_consumed = 5
      size.times do
        key, bc = decode(bytes, offset + bytes_consumed)
        bytes_consumed += bc
        value, bc = decode(bytes, offset + bytes_consumed)
        bytes_consumed += bc
        hash[key] = value
      end
      return hash, bytes_consumed
    end
  end
end