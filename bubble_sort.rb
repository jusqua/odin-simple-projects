# frozen_string_literal: true

def bubble_sort(list)
  (0...list.length).each_with_object(list) do |c, l|
    (0...(l.length - c - 1)).each do |i|
      l[i], l[i + 1] = l[i + 1], l[i] if l[i] > l[i + 1]
    end
  end
end

list = [4, 3, 78, 2, 0, 2]

puts bubble_sort(list)
