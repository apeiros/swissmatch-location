# encoding: utf-8
# This file provides a couple of ruby monkey patches.

module Enumerable
  unless method_defined?(:last) then

    # @example
    #     ary.last     ->  obj or nil
    #     ary.last(n)  ->  new_ary
    #
    # @return
    #   The last element(s) of self. If the enumerable is empty, the first form returns
    #   nil, the second an empty Array.
    #   The method is optimized to make use of reverse_each if present.
    def last(n=nil)
      reverse_each_method = method(:reverse_each)
      has_reverse_each    = reverse_each_method && reverse_each_method.owner != Enumerable # native reverse_each needed
      if n then
        return_value = []
        if has_reverse_each then
          reverse_each { |val|
            return_value.unshift(val)
            return return_value if return_value.size == n
          }
        else
          each { |val|
            return_value.push(val)
            return_value.shift if return_value.size > n
          }
        end
      else
        if has_reverse_each then
          reverse_each { |value| return value }
        else
          return_value = nil
          each { |value| return_value = value }
        end
      end

      return_value
    end
  end
end
