# frozen_string_literal: true

def substrings(text, dictionary)
  text = text.downcase

  dictionary.each_with_object({}) do |e, acc|
    e = e.downcase

    found = 0
    index = 0

    found += 1 while (index = text.index(e, index + 1))
    acc[e] = found if found != 0
  end
end

text = 'Howdy partner, sit down! How\'s it going?'
dictionary = %w[below down go going horn how howdy it i low own part partner sit]

puts substrings(text, dictionary)
