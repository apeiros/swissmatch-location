# encoding: utf-8



module SwissMatch
  class Name < ::String
    attr_reader :sequence_number
    attr_reader :language

    def initialize(name, language, sequence_number=0)
      @language         = language
      @sequence_number  = sequence_number
      super(name.to_s)
    end

    def to_hash
      {
        :name             => to_s,
        :language         => @language,
        :sequence_number  => @sequence_number,
      }
    end

    def inspect
      "#{super}(#{@language}, #{@running_number})"
    end
  end
end