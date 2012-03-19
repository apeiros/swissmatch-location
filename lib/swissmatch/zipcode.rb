# encoding: utf-8



require 'swissmatch/name'



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

    # @return [SwissMatch::Name]
    #   The official name of this zip code (max. 27 characters)
    attr_reader :name

    # @return [SwissMatch::Name]
    #   The official name of this zip code (max. 18 characters)
    attr_reader :name_short

    # @return [Symbol]
    #   The main language in the area of this zip code. One of :de, :fr, :it or :rt.
    attr_reader :language

    # @return [SwissMatch::Canton]
    #   The second most used language in the area of this zip code. One of :de, :fr, :it or :rt.
    attr_reader :language_alternative

    # @return [Boolean]
    #   Whether this ZipCode instance is included in the MAT[CH]sort sortfile
    attr_reader :sortfile_member

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
      names,
      name_short,
      names_short,
      canton,
      language,
      language_alternative,
      sortfile_member,
      delivery_by,
      community,
      valid_from,
      valid_until = nil
    )
      @ordering_number      = ordering_number
      @type                 = type
      @code                 = code
      @add_on               = add_on
      @full_code            = code*100 + add_on
      @language             = language
      @language_alternative = language_alternative
      @name                 = name.is_a?(Name) ? name : Name.new(name, language)
      @name_short           = name_short.is_a?(Name) ? name_short : Name.new(name_short, language)
      @names                = (names || [@name]).sort_by(&:running_number)
      @names_short          = (names_short || [@name_short]).sort_by(&:running_number)
      @canton               = canton
      @sortfile_member      = sortfile_member
      @delivery_by          = delivery_by == :self ? self : delivery_by
      @community            = community
      @valid_from           = valid_from
      @valid_until          = valid_until
    end

    # @return [Array<String>]
    #   The name of this zip code in all languages and normalizations (only unique values)
    def transliterated_names
      names.flat_map { |name, ary|
        SwissMatch.transliterate1(name)+
        SwissMatch.transliterate2(name)  # TODO: use transliterate gem
      }.uniq
    end

    # Since a zip code can - for any given language - have no name, exactly one name,
    # or even multiple names, it is sometimes difficult to write good code to
    # automatically provide well localized addresses. This method helps with that, in that
    # it guarantees a single name, as well chosen as possible.
    # It returns the name for the given language, and with the lowest running number, if
    # no name can be found for the given language, the primary name (@see #name) is
    # returned.
    #
    # @param [Symbol, nil] language
    #   One of nil, :de, :fr, :it or :rt
    #
    # @return [SwissMatch::Name]
    #   A single name for the zip code, chosen by a 'best fit' algorithm.
    def suggested_name(language=nil)
      (language && @names.find { |name| name.language == language }) || @name
    end


    # Since a zip code can - for any given language - have no name, exactly one name,
    # or even multiple names, it is sometimes difficult to write good code to
    # automatically provide well localized addresses. This method helps with that, in that
    # it guarantees a single name, as well chosen as possible.
    # It returns the name for the given language, and with the lowest running number, if
    # no name can be found for the given language, the primary name (@see #name) is
    # returned.
    #
    # @param [Symbol, nil] language
    #   One of nil, :de, :fr, :it or :rt
    #
    # @return [SwissMatch::Name]
    #   A single short name for the zip code, chosen by a 'best fit' algorithm.
    def suggested_short_name(language=nil)
      (language && @short_name.find { |name| name.language == language }) || @short_name
    end

    # @param [Symbol, nil] language
    #   One of nil, :de, :fr, :it or :rt
    #
    # @return [Array<SwissMatch::Name>]
    #   All official names (max. 27 chars) of this zip code.
    def names(language=nil)
      language ? @names.select { |name| name.language == language } : @names
    end

    # @param [Symbol, nil] language
    #   One of nil, :de, :fr, :it or :rt
    #
    # @return [Array<SwissMatch::Name>]
    #   All official short names (max. 18 chars) of this zip code.
    def names_short(language=nil)
      language ? @names_short.select { |name| name.language == language } : @names_short
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

    def to_hash(retain_references=false)
      delivery_by = retain_references ? @delivery_by : (@delivery_by && @delivery_by.ordering_number)
      community   = retain_references ? @community : (@community && @community.community_number)
      canton      = retain_references ? @canton : (@canton && @canton.license_tag)
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
        :canton               => canton,
        :language             => @language,
        :language_alternative => @language_alternative,
        :sortfile_member      => @sortfile_member,
        :delivery_by          => delivery_by,
        :community            => community,
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
