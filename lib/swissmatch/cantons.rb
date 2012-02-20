# encoding: utf-8



require 'swissmatch/canton'



module SwissMatch

  # Represents a collection of swiss cantons and provides a query interface.
  class Cantons
    include Enumerable

    # @param [Array<SwissMatch::Canton>] cantons
    #   The SwissMatch::Canton objects this SwissMatch::Cantons should contain
    def initialize(cantons)
      @cantons        = cantons
      @by_license_tag = {}
      @by_name        = {}

      cantons.each do |canton|
        @by_license_tag[canton.license_tag] = canton
        canton.names.each do |name|
          @by_name[name] = canton
        end
      end
    end

    # Calls the block once for every SwissMatch::Canton in this SwissMatch::Cantons
    # instance, passing that canton as a parameter.
    # The order is the same as the instance was constructed.
    #
    # @yield [canton]
    # @yieldparam [SwissMatch::Canton] canton
    #
    # @return [self] Returns self
    def each(&block)
      @cantons.each(&block)
      self
    end

    # Calls the block once for every SwissMatch::Canton in this SwissMatch::Cantons
    # instance, passing that canton as a parameter.
    # The order is the reverse of what the instance was constructed.
    #
    # @yield [canton]
    # @yieldparam [SwissMatch::Canton] canton
    #
    # @return [self] Returns self
    def reverse_each(&block)
      @cantons.reverse_each(&block)
      self
    end

    # @return [SwissMatch::Canton]
    #   The canton with the given license tag or name (in any language)
    def [](key)
      @by_license_tag[key] || @by_name[name]
    end

    # @return [SwissMatch::Canton]
    #   The canton with the given license tag.
    def by_license_tag(tag)
      @by_license_tag[tag]
    end

    # @return [SwissMatch::Canton]
    #   The canton with the given name (any language)
    def by_name(name)
      @by_name[name]
    end

    # @return [Integer] The number of SwissMatch::Canton objects in this collection.
    def size
      @cantons.size
    end

    # @return [Array<SwissMatch::Canton>]
    #   An Array with all SwissMatch::Canton objects in this SwissMatch::Cantons.
    def to_a
      @cantons.dup
    end
  end
end
