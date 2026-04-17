# frozen_string_literal: true

def constrained_shift(val, low, high, key)
  nval = val + key
  if nval > high
    nval - high + low - 1
  elsif nval < low
    high - (low - nval) + 1
  else
    nval
  end
end

def caesar_cipher(text, key)
  (text.bytes.map do |e|
    if e >= 65 && e <= 90
      constrained_shift(e, 65, 90, key)
    elsif e >= 97 && e <= 122
      constrained_shift(e, 97, 122, key)
    else
      e
    end
  end).pack('c*')
end

puts caesar_cipher(caesar_cipher('What a string!', 5), -5)
