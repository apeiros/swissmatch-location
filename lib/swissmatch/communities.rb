# encoding: utf-8



module SwissMatch

  # Represents a collection of SwissMatch::Community objects and provides a query
  # interface.
  class Communities
    include Enumerable

    # @param [Array<SwissMatch::Community>] communities
    #   The SwissMatch::Community objects this SwissMatch::Communities should contain
    def initialize(communities)
      @all                  = communities
      @by_community_number  = Hash[communities.map { |c| [c.community_number, c] }]
      @by_name              = {}
      communities.each do |community|
        @by_name[community.name.to_s] = community
      end

      unless communities.size == @by_name.size
        raise "ImplementationError: The author assumed communities to have a unique name, which doesn't seem to be the case anymore"
      end
    end

    # Calls the block once for every SwissMatch::Community in this SwissMatch::Communities
    # instance, passing that community as a parameter.
    # The order is the same as the instance was constructed.
    #
    # @yield [community]
    # @yieldparam [SwissMatch::Community] community
    #
    # @return [self] Returns self
    def each(&block)
      @all.each(&block)
      self
    end

    # Calls the block once for every SwissMatch::Community in this SwissMatch::Communities
    # instance, passing that community as a parameter.
    # The order is the reverse of what the instance was constructed.
    #
    # @yield [community]
    # @yieldparam [SwissMatch::Community] community
    #
    # @return [self] Returns self
    def reverse_each(&block)
      @all.reverse_each(&block)
      self
    end

    # @return [SwissMatch::Community]
    #   The community with the given name or community number.
    def [](key)
      @by_name[key] || @by_community_number[key.to_i]
    end

    # @return [SwissMatch::Community]
    #   The community with the given community number (also known as BFSNR).
    def by_community_number(number)
      @by_community_number[number]
    end

    # @return [SwissMatch::Community]
    #   The community with the given name.
    def by_name(name)
      @by_name[name]
    end

    # @return [SwissMatch::Communities]
    #   A SwissMatch::Communities collection with all SwissMatch::Community objects for which the block
    #   returned true (or a trueish value)
    def select(*args, &block)
      Communities.new(@all.select(*args, &block))
    end

    # @return [SwissMatch::Communities]
    #   A SwissMatch::Communities collection with all SwissMatch::Community objects for which the block
    #   returned false (or a falseish value)
    def reject(*args, &block)
      Communities.new(@all.reject(*args, &block))
    end

    # @return [Integer] The number of SwissMatch::Community objects in this collection.
    def size
      @all.size
    end

    # @return [Array<SwissMatch::Community>]
    #   An Array with all SwissMatch::Community objects in this SwissMatch::Communities.
    def to_a
      @all.dup
    end

    # @private
    # @see Object#inspect
    def inspect
      sprintf "\#<%s:%x size: %d>", self.class, object_id>>1, size
    end
  end
end
