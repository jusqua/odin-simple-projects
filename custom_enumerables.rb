# frozen_string_literal: true

# rubocop: disable Style

module Enumerable
  def my_each_with_i
    return to_enum(:my_each_with_i) unless block_given?

    i = 0
    for e in self
      yield e, i
      i += 1
    end
  end

  def my_select
    return to_enum(:my_select) unless block_given?

    elems = self.class.new
    for e in self
      elems << e if yield e
    end
    elems
  end

  def my_all?
    return to_enum(:my_all?) unless block_given?

    for e in self
      return false unless yield e
    end
    true
  end

  def my_any?
    return to_enum(:my_any?) unless block_given?

    for e in self
      return true if yield e
    end
    false
  end

  def my_none?
    return to_enum(:my_none?) unless block_given?

    for e in self
      return false if yield e
    end
    true
  end

  def my_count
    return size unless block_given?

    for e in self
      c += 1 if yield e
    end
  end

  def my_map
    return to_enum(:my_map) unless block_given?

    elems = self.class.new
    for e in self
      elems << yield(e)
    end
    elems
  end

  def my_inject(initial_value)
    return to_enum(:my_inject, initial_value) unless block_given?

    value = initial_value
    for e in self
      value = yield(value, e)
    end
    value
  end
end

class Array
  def my_each
    return to_enum(:my_each) unless block_given?

    for e in self
      yield e
    end
  end
end

# rubocop: enable Style
