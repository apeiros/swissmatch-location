# encoding: utf-8



module SwissMatch

  # Represents a collection of SwissMatch::Community objects and provides a query
  # interface.
  class Communities
    include Enumerable

    # @param [Array<SwissMatch::Community>] communities
    #   The SwissMatch::Community objects this SwissMatch::Communities should contain
    def initialize(communities)
      @communities          = communities
      reset!
    end

    # @private
    # Reinitialize all caching instance variables
    def reset!
      @by_community_number  = Hash[@communities.map { |c| [c.community_number, c] }]
      @by_name              = {}
      @communities.each do |community|
        @by_name[community.name.to_s] = community
      end

      unless @communities.size == @by_name.size
        count=Hash.new(0)
        @communities.each do |community| count[community.name.to_s] += 1 end
        non_unique = count.select { |k,v| v > 1 }.map(&:first)

        raise "ImplementationError: The author assumed communities to have a unique name, which doesn't seem to be the case anymore. Non-unique names: #{non_unique.inspect}"
      end

      self
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
      @communities.each(&block)
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
      @communities.reverse_each(&block)
      self
    end

    # @return [SwissMatch::Communities]
    #   A SwissMatch::Communities collection with all SwissMatch::Community objects for which the block
    #   returned true (or a trueish value)
    def select(*args, &block)
      Communities.new(@communities.select(*args, &block))
    end

    # @return [SwissMatch::Communities]
    #   A SwissMatch::Communities collection with all SwissMatch::Community objects for which the block
    #   returned false (or a falseish value)
    def reject(*args, &block)
      Communities.new(@communities.reject(*args, &block))
    end

    # @see Enumerable#sort
    #
    # @return [SwissMatch::Communities]
    #   A SwissMatch::Communities collection sorted by the block
    def sort(*args, &block)
      Communities.new(@communities.sort(*args, &block))
    end

    # @see Enumerable#sort_by
    #
    # @return [SwissMatch::Communities]
    #   A SwissMatch::Communities collection sorted by the block
    def sort_by(*args, &block)
      Communities.new(@communities.sort_by(*args, &block))
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

    # @return [Integer] The number of SwissMatch::Community objects in this collection.
    def size
      @communities.size
    end

    # @return [Array<SwissMatch::Community>]
    #   An Array with all SwissMatch::Community objects in this SwissMatch::Communities.
    def to_a
      @communities.dup
    end

    # @private
    # @see Object#inspect
    def inspect
      sprintf "\#<%s:%x size: %d>", self.class, object_id>>1, size
    end
  end
end
