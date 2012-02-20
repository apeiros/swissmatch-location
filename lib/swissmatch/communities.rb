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
      @by_name              = Hash[communities.map { |c| [c.name, c] }]
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
      @by_name[key] || by_community_number[key.to_i]
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
      @all.size
    end

    # @return [Array<SwissMatch::Community>]
    #   An Array with all SwissMatch::Community objects in this SwissMatch::Communities.
    def to_a
      @all.dup
    end
  end
end
