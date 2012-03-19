# encoding: utf-8



module SwissMatch
  class Name < ::String
    attr_reader :running_number
    attr_reader :language

    def initialize(name, language, running_number=0)
      @language       = language
      @running_number = running_number
      super(name.to_s)
    end

    def inspect
      "#{super}(#{@language}, #{@running_number})"
    end
  end
end