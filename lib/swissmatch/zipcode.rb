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

    # @note This method exists mostly for internal purposes
    #
    # @return [String]
    #   All names, short and long, as strings, without sequence number nor language.
    attr_reader :all_names

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
    #   The largest community which belongs to this zip code.
    attr_reader :largest_community

    # @return [SwissMatch::Communities]
    #   The communities which belong to this zip code.
    attr_reader :communities

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
      region_names,
      region_names_short,
      canton,
      language,
      language_alternative,
      sortfile_member,
      delivery_by,
      largest_community,
      communities,
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
      @names                = (names || [@name]).sort_by(&:sequence_number)
      @names_short          = (names_short || [@name_short]).sort_by(&:sequence_number)
      @all_names            = @names.map(&:to_s) | @names_short.map(&:to_s)
      @region_names         = region_names
      @region_names_short   = region_names_short
      @canton               = canton
      @sortfile_member      = sortfile_member
      @delivery_by          = delivery_by == :self ? self : delivery_by
      @largest_community    = largest_community
      @communities          = communities
      @valid_from           = valid_from
      @valid_until          = valid_until
    end

    # @return [String]
    #   The zip code add-on as 2 digit string, with leading zeros if necessary
    def two_digit_add_on
      "%02d" % @add_on
    end

    # @return [Array<String>]
    #   The name of this zip code in all languages and normalizations (only unique values)
    def transliterated_names
      (
        @all_names.map { |name| SwissMatch.transliterate1(name) } |
        @all_names.map { |name| SwissMatch.transliterate2(name) }
      ).uniq
    end

    # @return [Hash<String, String>]
    #   A map to get the names which match a transliteration
    def reverse_name_transliteration_map
      result = {}
      @all_names.map { |name|
        trans_name1 = SwissMatch.transliterate1(name)
        trans_name2 = SwissMatch.transliterate2(name)
        result[trans_name1] ||= []
        result[trans_name2] ||= []
        result[trans_name1] << name
        result[trans_name2] << name
      }
      result.each_value(&:uniq!)

      result
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

    # A region name is a name that can be used along a zip code and city, but must not replace
    # the city. For more information, read the section about the PLZ_P2 file, "Bezeichnungstyp"
    # with value "3".
    #
    # @param [Symbol, nil] language
    #   One of nil, :de, :fr, :it or :rt
    #
    # @return [Array<SwissMatch::Name>]
    #   All official region names (max. 27 chars) of this zip code.
    def region_names(language=nil)
      language ? @region_names.select { |name| name.language == language } : @region_names
    end

    # A region name is a name that can be used along a zip code and city, but must not replace
    # the city. For more information, read the section about the PLZ_P2 file, "Bezeichnungstyp"
    # with value "3".
    #
    # @param [Symbol, nil] language
    #   One of nil, :de, :fr, :it or :rt
    #
    # @return [Array<SwissMatch::Name>]
    #   All official short region names (max. 18 chars) of this zip code.
    def region_names_short(language=nil)
      language ? @region_names_short.select { |name| name.language == language } : @region_names_short
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

    # @param [Boolean] retain_references
    #   If set to false, :delivery_by will be set to the ordering number,
    #   :largest_community to the community_number, :communities to their respective
    #   community numbers and :canton to the canton's license_tag.
    #
    # @return [Hash]
    #   All properties of the zip code as a hash.
    def to_hash(retain_references=false)
      delivery_by       = retain_references ? @delivery_by : (@delivery_by && @delivery_by.ordering_number)
      largest_community = retain_references ? @largest_community : (@largest_community && @largest_community.community_number)
      communities       = retain_references ? @communities : @communities.map(&:community_number)
      canton            = retain_references ? @canton : (@canton && @canton.license_tag)
      {
        :ordering_number      => @ordering_number,
        :type                 => @type,
        :code                 => @code,
        :add_on               => @add_on,
        :name                 => @name,
        :name_short           => @name_short,
        :canton               => canton,
        :language             => @language,
        :language_alternative => @language_alternative,
        :sortfile_member      => @sortfile_member,
        :delivery_by          => delivery_by,
        :largest_community    => largest_community,
        :communities          => communities,
        :valid_from           => @valid_from,
        :valid_until          => @valid_until,
      }
    end

    # @private
    # @see Object#hash
    def hash
      [self.class, @ordering_number].hash
    end

    # @private
    # @see Object#eql?
    def eql?(other)
      self.class.eql?(other.class) && @ordering_number.eql?(other.ordering_number)
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
