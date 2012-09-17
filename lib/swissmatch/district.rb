# encoding: utf-8



module SwissMatch

  # Represents a swiss district.
  class District

    # @return [String]
    #   The district number.
    attr_reader :district_number

    # @return [String]
    #   The name of the district.
    attr_reader :name

    # @return [SwissMatch::Communities]
    #   The political communities belonging to this district
    attr_reader :communities

    attr_reader :canton

    # @param [String] district_number
    #   The two letter abbreviation of the districts name as used on license plates.
    # @param [String] name
    #   The official name of the district.
    # @param [SwissMatch::Canton] canton
    #   The canton this district belongs to
    # @param [SwissMatch::Communities] communities
    #   The communities belonging to this district
    def initialize(district_number, name, canton, communities)
      @district_number  = district_number
      @name             = name
      @canton           = canton
      @communities      = communities
    end

    # @param [Boolean] retain_references
    #   If set to false, :agglomeration will be set to the community_number and
    #   :canton to the canton's license_tag.
    #
    # @return [Hash]
    #   All properties of the district as a hash.
    def to_hash(retain_references=false)
      if retain_references
        canton        = @canton
        communities   = @communities
      else
        canton        = @canton && @canton.license_tag
        communities   = @communities.map(&:community_number)
      end

      {
        :name             => @name,
        :district_number  => @district_number,
        :canton           => canton,
        :communities      => communities,
      }
    end

    alias to_s name

    # @private
    # @see Object#hash
    def hash
      [self.class, @number].hash
    end

    # @private
    # @see Object#eql?
    def eql?(other)
      self.class.eql?(other.class) && @number.eql?(other.number)
    end

    # @return [String]
    # @see Object#inspect
    def inspect
      sprintf "\#<%s:%014x %d %p>", self.class, object_id, @district_number, to_s
    end
  end
end
