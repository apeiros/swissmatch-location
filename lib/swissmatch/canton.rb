# encoding: utf-8



module SwissMatch

  # Represents a swiss canton.
  class Canton

    # @return [String]
    #   The two letter abbreviation of the cantons name as used on license plates.
    attr_reader :license_tag

    # @param [String] license_tag
    #   The two letter abbreviation of the cantons name as used on license plates.
    # @param [String] name
    #   The official name of the canton in the local language.
    # @param [String] name_de
    #   The official name of the canton in german.
    # @param [String] name_fr
    #   The official name of the canton in french.
    # @param [String] name_it
    #   The official name of the canton in italian.
    # @param [String] name_rt
    #   The official name of the canton in rhaeto-romanic.
    def initialize(license_tag, name, name_de, name_fr, name_it, name_rt)
      @license_tag  = license_tag
      @name         = name
      @names        = {
        :de => name_de,
        :fr => name_fr,
        :it => name_it,
        :rt => name_rt,
      }
    end

    # The name of the canton. If no language is passed, the local language is used.
    #
    # @param [Symbol, nil] language
    #   One of nil, :de, :fr, :it or :rt
    def name(language=nil)
      language ? @names[language] : @name
    end

    # @return [Array<String>]
    #   The name of this zip code in all languages (only unique names)
    def names
      @names.values.uniq
    end

    def to_hash
      {
        :name         => @name,
        :name_de      => @names[:de],
        :name_fr      => @names[:fr],
        :name_it      => @names[:it],
        :name_rt      => @names[:rt],
        :license_tag  => @license_tag
      }
    end

    alias to_s name

    def hash
      [self.class, @license_tag].hash
    end

    def eql?(other)
      self.class == other.class && @license_tag == other.license_tag
    end

    # @return [String]
    # @see Object#inspect
    def inspect
      sprintf "\#<%s:%014x %s>", self.class, object_id, self
    end
  end
end
