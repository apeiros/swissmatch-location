# encoding: utf-8



module SwissMatch

  # Represents a swiss community.
  # Swiss communities are identified by their community number (BFSNR).
  class Community

    # @return [Integer]
    #   A unique, never recycled identification number.
    #   Also known as BFSNR.
    attr_reader :community_number

    # @return [String]
    #   The official name of the community.
    attr_reader :name

    # @return [SwissMatch::Canton]
    #   The canton this community belongs to.
    attr_reader :canton

    # @return [SwissMatch::Community]
    #   The community this community is considered to be an agglomeration of.
    #   Note that a main community will reference itself.
    attr_reader :agglomeration

    # @param [Integer] community_number
    #   The identification number of the community, also known as BFSNR.
    # @param [String] name
    #   The official name of the community
    # @param [SwissMatch::Canton] canton
    #   The canton this community belongs to
    # @param [SwissMatch::Community]
    #   The community this community is considered to be an agglomeration of.
    #   Note that a main community will reference itself.
    def initialize(community_number, name, canton, agglomeration)
      @community_number = community_number
      @name             = name
      @canton           = canton
      @agglomeration    = agglomeration == :self ? self : agglomeration
    end

    alias to_s name

    def to_hash
      {
        :community_number => @community_number,
        :name             => @name,
        :canton           => @canton,
        :agglomeration    => @agglomeration,
      }
    end

    def hash
      [self.class, @community_number]
    end

    def eql?(other)
      self.class == other.class && @community_number == other.community_number
    end

    # @return [String]
    # @see Object#inspect
    def inspect
      sprintf "\#<%s:%014x %s, BFSNR %d>", self.class, object_id, self, @community_number
    end
  end
end
