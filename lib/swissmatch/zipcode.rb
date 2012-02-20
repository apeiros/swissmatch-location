# encoding: utf-8



module SwissMatch

  # Represents an area, commonly identified by zip-code and city-name.
  # A unique zip code is determined by any of these:
  # * the postal ordering number
  # * zip code + zip code add on
  # * zip code + name (city)
  class ZipCode

    # @return [Integer]
    #   The postal ordering number, also known as ONRP
    attr_reader :ordering_number # onrp

    # Described under "PLZ light", as field "PLZ-Typ"
    # * 10 = Domizil- und Fachadressen
    # * 20 = Nur Domiziladressen
    # * 30 = Nur Fach-PLZ
    # * 40 = Firmen-PLZ
    # * 80 = Postinterne PLZ (Angabe Zustellpoststelle auf Bundzetteln oder auf Sackanschriften)
    #
    # @return [Integer]
    #   The type of the zip code in a numeric code, one of the values 10, 20, 30, 40 or 80.
    attr_reader :type

    # Described under "PLZ light", as field "Postleitzahl"
    #
    # @return [Integer]
    #   The 4 digit numeric zip code
    attr_reader :code

    # @return [Integer]
    #   The 2 digit numeric code addition, to distinguish zip codes with the same 4 digit code.
    attr_reader :add_on

    # @return [Integer]
    #   The 6 digit numeric zip code and add-on (first 4 digits are the code, last 2
    #   digits the add-on).
    attr_reader :full_code

    # @return [SwissMatch::Canton]
    #   The canton this zip code belongs to
    attr_reader :canton

    # @return [Symbol]
    #   The main language in the area of this zip code. One of :de, :fr, :it or :rt.
    attr_reader :language

    # @return [SwissMatch::Canton]
    #   The second most used language in the area of this zip code. One of :de, :fr, :it or :rt.
    attr_reader :language_alternative

    # @return [Boolean]
    #   Whether this ZipCode instance is included in the MAT[CH]sort sortfile
    attr_reader :sortfile_member

    # @todo This method currently returns the ONRP instead of the ZipCode
    # @return [SwissMatch::ZipCode]
    #   By which postal office delivery of letters is usually taken care of.
    attr_reader :delivery_by

    # @return [SwissMatch::Community]
    #   The community this zip code belongs to.
    attr_reader :community

    # @return [Date, nil]
    #   The date from which on this zip code starts to be in use
    #
    # @see #in_use?
    attr_reader :valid_from

    # @return [Date, nil]
    #   The date until which on this zip code is in use
    #
    # @see #in_use?
    attr_reader :valid_until

    def initialize(
      ordering_number,
      type,
      code,
      add_on,
      name,
      name_de,
      name_fr,
      name_it,
      name_rt,
      name_short,
      name_short_de,
      name_short_fr,
      name_short_it,
      name_short_rt,
      canton,
      language,
      language_alternative,
      sortfile_member,
      delivery_by,
      community,
      valid_from,
      valid_until = nil
    )
      @ordering_number = ordering_number
      @type            = type
      @code            = code
      @add_on          = add_on
      @full_code       = code*100 + add_on
      @name            = name
      @name_short      = name_short
      @names           = {
        :de => name_de || name,
        :fr => name_fr || name,
        :it => name_it || name,
        :rt => name_rt || name,
      }
      @names_short            = {
        :de => name_short_de || name_short,
        :fr => name_short_fr || name_short,
        :it => name_short_it || name_short,
        :rt => name_short_rt || name_short,
      }
      @canton               = canton
      @language             = language
      @language_alternative = language_alternative
      @sortfile_member      = sortfile_member
      @delivery_by          = delivery_by
      @community            = community
      @valid_from           = valid_from
      @valid_until          = valid_until
    end

    # @return [Array<String>]
    #   The name of this zip code in all languages and normalizations (only unique values)
    def transliterated_names
      names.each_with_object([]) { |name, ary|
        ary.concat(SwissMatch.transliterate1(name).split(" "))
        ary.concat(SwissMatch.transliterate2(name).split(" ")) # TODO: use transliterate gem
      }.uniq
    end

    # @return [Array<String>]
    #   The name of this zip code in all languages (only unique names)
    def names
      @names.values.uniq
    end

    # The name that belongs to this zip code. At a maximum 27 characters long.
    #
    # @param [Symbol, nil] language
    #   One of nil, :de, :fr, :it or :rt
    def name(language=nil)
      language ? @names[language] : @name
    end

    # The name that belongs to this zip code. At a maximum 18 characters long.
    #
    # @param [Symbol, nil] language
    #   One of nil, :de, :fr, :it or :rt
    def name_short(language=nil)
      language ? @names_short[language] : @name_short
    end

    # Compare two zip codes by their ordering number (ONRP)
    #
    # @return [Integer]
    #   Returns -1, 0 or 1.
    def <=>(other)
      @ordering_number <=> other.ordering_number
    end

    # @param [Date] at
    #   The date for which to check the 
    #
    # @return [Boolean]
    #   Whether the zip code is in active use at the given date.
    def in_use?(at=Date.today)
      if @valid_from then
        if @valid_until then
          at.between?(@valid_from, @valid_until)
        else
          at >= @valid_from
        end
      elsif @valid_until
        at <= @valid_until
      else
        true
      end
    end

    def to_hash
      {
        :ordering_number      => @ordering_number,
        :type                 => @type,
        :code                 => @code,
        :add_on               => @add_on,
        :name                 => @name,
        :name_de              => @names[:de],
        :name_fr              => @names[:fr],
        :name_it              => @names[:it],
        :name_rt              => @names[:rt],
        :canton               => @canton,
        :language             => @language,
        :language_alternative => @language_alternative,
        :sortfile_member      => @sortfile_member,
        :delivery_by          => @delivery_by,
        :community            => @community,
        :valid_from           => @valid_from,
        :valid_until          => @valid_until,
      }
    end

    def hash
      [self.class, @ordering_number].hash
    end

    def eql?(other)
      self.class == other.class && @ordering_number == other.ordering_number
    end

    # @return [String]
    #   The 4 digit code, followed by the name
    def to_s
      "#{@code} #{@name}"
    end

    # @return [String]
    # @see Object#inspect
    def inspect
      sprintf "\#<%s:%014x %s>", self.class, object_id, self
    end
  end
end
