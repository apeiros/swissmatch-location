# encoding: utf-8



module SwissMatch

  # Adds a couple of properties to the String class.
  # These properties are relevant to the naming of Cantons, Communities and
  # ZipCodes. They provide information about the language in which the name is,
  # and which sequence number that name has.
  class Name < ::String

    # @return [Integer] The sequence number of this name
    attr_reader :sequence_number

    # @return [Symbol] The language of this name (:de, :fr, :it or :rt)
    attr_reader :language

    # @param [String] name
    #   The name (self)
    # @param [Symbol] language
    #   The language this name is in (:de, :fr, :it or :rt)
    # @param [Integer] sequence_number
    #   The sequence number of this name
    def initialize(name, language, sequence_number=0)
      @language         = language
      @sequence_number  = sequence_number
      super(name.to_s)
    end

    # @return [Hash]
    #   All properties of the name as a hash.
    def to_hash
      {
        :name             => to_s,
        :language         => @language,
        :sequence_number  => @sequence_number,
      }
    end

    # @private
    # @see Object#inspect
    def inspect
      "#{super}(#{@language}, #{@sequence_number})"
    end
  end
end