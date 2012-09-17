# encoding: utf-8



require 'swissmatch/district'



module SwissMatch

  # Represents a collection of swiss districts and provides a query interface.
  class Districts
    include Enumerable

    # @param [Array<SwissMatch::District>] districts
    #   The SwissMatch::District objects this SwissMatch::Districts should contain
    def initialize(districts)
      @districts          = districts
      @by_district_number = {}
      @by_name            = {}

      districts.each do |district|
        @by_district_number[district.district_number] = district
        @by_name[district.name]                       = district
      end
    end

    # Calls the block once for every SwissMatch::District in this SwissMatch::Districts
    # instance, passing that district as a parameter.
    # The order is the same as the instance was constructed.
    #
    # @yield [district]
    # @yieldparam [SwissMatch::District] district
    #
    # @return [self] Returns self
    def each(&block)
      @districts.each(&block)
      self
    end

    # Calls the block once for every SwissMatch::District in this SwissMatch::Districts
    # instance, passing that district as a parameter.
    # The order is the reverse of what the instance was constructed.
    #
    # @yield [district]
    # @yieldparam [SwissMatch::District] district
    #
    # @return [self] Returns self
    def reverse_each(&block)
      @districts.reverse_each(&block)
      self
    end

    # @return [SwissMatch::Districts]
    #   A SwissMatch::Districts collection with all SwissMatch::District objects for which the block
    #   returned true (or a trueish value)
    def select(*args, &block)
      Districts.new(@districts.select(*args, &block))
    end

    # @return [SwissMatch::Districts]
    #   A SwissMatch::Districts collection with all SwissMatch::District objects for which the block
    #   returned false (or a falseish value)
    def reject(*args, &block)
      Districts.new(@districts.reject(*args, &block))
    end

    # @see Enumerable#sort
    #
    # @return [SwissMatch::Districts]
    #   A SwissMatch::Districts collection sorted by the block
    def sort(*args, &block)
      Districts.new(@districts.sort(*args, &block))
    end

    # @see Enumerable#sort_by
    #
    # @return [SwissMatch::Districts]
    #   A SwissMatch::Districts collection sorted by the block
    def sort_by(*args, &block)
      Districts.new(@districts.sort_by(*args, &block))
    end

    # @return [SwissMatch::District]
    #   The district with the given district_number or name
    def [](district_number_or_name)
      @by_district_number[district_number_or_name] || @by_name[district_number_or_name]
    end

    # @return [SwissMatch::District]
    #   The district with the given license tag.
    def by_district_number(tag)
      @by_district_number[tag]
    end

    # @return [SwissMatch::District]
    #   The district with the given name (any language)
    def by_name(name)
      @by_name[name]
    end

    # @return [Integer] The number of SwissMatch::District objects in this collection.
    def size
      @districts.size
    end

    # @return [Array<SwissMatch::District>]
    #   An Array with all SwissMatch::District objects in this SwissMatch::Districts.
    def to_a
      @districts.dup
    end

    # @private
    # @see Object#inspect
    def inspect
      sprintf "\#<%s:%x size: %d>", self.class, object_id>>1, size
    end
  end
end
