# encoding: utf-8



require 'autocompletion'
require 'unicode'



module SwissMatch

  # Represents a collection of SwissMatch::ZipCode objects, and provides a query interface.
  class ZipCodes
    include Enumerable

    # @param [Array<SwissMatch::ZipCode>] zip_codes
    #   The SwissMatch::ZipCode objects this SwissMatch::ZipCodes should contain
    def initialize(zip_codes)
      @zip_codes          = zip_codes
      reset!
    end

    # @private
    # Reinitialize all caching instance variables
    def reset!
      @by_ordering_number = nil
      @by_code            = nil
      @by_full_code       = nil
      @by_code_and_name   = nil
      @by_name            = nil
      @autocomplete       = nil

      self
    end

    # A convenience method to get one or many zip codes by code, code and add-on, code and city or just
    # city.
    # There are various allowed styles to pass those values.
    # All numeric values can be passed either as Integer or String.
    # You can pass the code and add-on as six-digit number, or you can pass the code
    # as four digit number plus either the add-on or name as second parameter. Or you can
    # pass the code alone, or the name alone.
    #
    # @example All usage styles
    #   zip_codes[805200]           # zip code 8052, add-on 0
    #   zip_codes["805200"]         # zip code 8052, add-on 0
    #   zip_codes[8052, 0]          # zip code 8052, add-on 0
    #   zip_codes["8052", 0]        # zip code 8052, add-on 0
    #   zip_codes[8052, "0"]        # zip code 8052, add-on 0
    #   zip_codes["8052", 0]        # zip code 8052, add-on 0
    #   zip_codes[8052, "Zürich"]   # zip code 8052, add-on 0
    #   zip_codes["8052", "Zürich"] # zip code 8052, add-on 0
    #   zip_codes[8052]             # all zip codes with code 8052
    #   zip_codes["8052"]           # all zip codes with code 8052
    #   zip_codes["Zürich"]         # all zip codes with name "Zürich"
    #
    # @see #by_code_and_add_on  Get a zip code by code and add-on directly
    # @see #by_code_and_name    Get a zip code by code and name directly
    # @see #by_name             Get a collection of zip codes by name directly
    # @see #by_ordering_number  Get a zip code by its ONRP directly (#[] can't do that)
    #
    # @param [String, Integer] key
    #   Either the zip code, zip code and add-on
    # @return [SwissMatch::ZipCode, SwissMatch::ZipCodes]
    #   Either a SwissMatch::ZipCodes collection of zip codes or a single SwissMatch::ZipCode, depending on
    #   the argument you pass.
    def [](key, add_on=nil)
      case key
        when /\A(\d{4})(\d\d)\z/
          by_code_and_add_on($1.to_i, $2.to_i)
        when 100_000..999_999
          by_code_and_add_on(*key.divmod(100))
        when 0..9999, /\A\d{4}\z/
          case add_on
            when nil
              by_code(key.to_i)
            when 0..99, /\A\d+\z/
              by_code_and_add_on(key.to_i, add_on.to_i)
            when String
              by_code_and_name(key.to_i, add_on)
            else
              raise ArgumentError,
                    "Expected a String, an Integer between 0 and 99, or a String containing an integer between 0 and 99, " \
                    "but got #{key.class}: #{key.inspect}"
          end
        when String
          by_name(key)
        else
          raise ArgumentError,
                "Expected a String, an Integer between 1000 and 9999, or an " \
                "Integer between 100_000 and 999_999, but got #{key.class}:" \
                "#{key.inspect}"
      end
    end

    # Calls the block once for every SwissMatch::ZipCode in this SwissMatch::ZipCodes
    # instance, passing that zip_code as a parameter.
    # The order is the same as the instance was constructed.
    #
    # @yield [zip_code]
    # @yieldparam [SwissMatch::ZipCode] zip_code
    #
    # @return [self] Returns self
    def each(&block)
      @zip_codes.each(&block)
      self
    end

    # Calls the block once for every SwissMatch::ZipCode in this SwissMatch::ZipCodes
    # instance, passing that zip_code as a parameter.
    # The order is the reverse of what the instance was constructed.
    #
    # @yield [zip_code]
    # @yieldparam [SwissMatch::ZipCode] zip_code
    #
    # @return [self] Returns self
    def reverse_each(&block)
      @zip_codes.reverse_each(&block)
      self
    end

    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection with all SwissMatch::ZipCode objects for which the block
    #   returned true (or a trueish value)
    def select(*args, &block)
      ZipCodes.new(@zip_codes.select(*args, &block))
    end

    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection with all SwissMatch::ZipCode objects for which the block
    #   returned false (or a falseish value)
    def reject(*args, &block)
      ZipCodes.new(@zip_codes.reject(*args, &block))
    end

    # @see Enumerable#sort
    #
    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection sorted by the block.
    def sort(*args, &block)
      ZipCodes.new(@zip_codes.sort(*args, &block))
    end

    # @see Enumerable#sort_by
    #
    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection sorted by the block.
    def sort_by(*args, &block)
      ZipCodes.new(@zip_codes.sort_by(*args, &block))
    end

    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection with zip codes that are currently active/in use.
    def active(date=Date.today, &block)
      select { |zip_code| zip_code.in_use?(date) }
    end

    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection with zip codes that are currently inactive/not in use.
    #   A zip code is not in use if it has been either retired or is only recorded for future use.
    def inactive(date=Date.today, &block)
      reject { |zip_code| zip_code.in_use?(date) }
    end

    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection with zip codes having names that match
    #   the given string (prefix search on all languages)
    def autocomplete(string)
      return ZipCodes.new([]) if string.empty? # shortcut

      @autocomplete ||= AutoCompletion.map_keys(@zip_codes) { |zip_code|
        zip_code.transliterated_names
      }
      words = SwissMatch.transliterated_words(string)

      ZipCodes.new(@autocomplete.complete(*words))
    end

    # @return [Array<String>]
    #   An array of ZipCode names which match the given string in an autocompletion.
    #   Sorted alphabetically (Umlaut-aware)
    def autocompleted_names(name)
      name_dc = Unicode.downcase(name)
      len     = name_dc.length
      base    = autocomplete(name)
      names   = base.flat_map { |zip_code|
        zip_code.reverse_name_transliteration_map.select { |transliterated_name, real_names|
          Unicode.downcase(transliterated_name[0, len]) == name_dc
        }.values.flatten(1)
      }

      names.uniq.sort(&Unicode.method(:strcmp))
    end

    # @return [Array<String>]
    #   An array of ZipCode names suitable for presentation of a select.
    def names_for_select(language=nil)
      if language
        names = flat_map { |zip_code| [zip_code.name, zip_code.suggested_name(I18n.language)] }
      else
        names = map(&:name)
      end

      names.uniq.sort(&Unicode.method(:strcmp))
    end

    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection with zip codes of type 10 and 20.
    def residential
      with_type(10, 20)
    end

    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection consisting only of zip codes having the given type(s).
    def with_type(*types)
      select { |zip_code| types.include?(zip_code.type) }
    end

    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection consisting only of zip codes not having the given type(s).
    def without_type(*types)
      reject { |zip_code| types.include?(zip_code.type) }
    end

    # @return [SwissMatch::ZipCode] 
    #   The SwissMatch::ZipCode with the given ordering number (ONRP).
    def by_ordering_number(onrp)
      @by_ordering_number ||= Hash[@zip_codes.map { |c| [c.ordering_number, c] }]
      @by_ordering_number[onrp]
    end

    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection with all SwissMatch::ZipCode objects having the given 4 digit code.
    def by_code(code)
      ZipCodes.new(by_code_lookup_table[code] || [])
    end

    # @return [SwissMatch::ZipCode]
    #   The SwissMatch::ZipCode with the given 4 digit code and given 2 digit code add-on.
    def by_code_and_add_on(code, add_on)
      by_full_code_lookup_table[code*100+add_on]
    end

    # @return [SwissMatch::ZipCode]
    #   The SwissMatch::ZipCode with the given 4 digit code and name in any language.
    def by_code_and_name(code, name)
      by_code_and_name_lookup_table[[code, name]]
    end

    # @return [SwissMatch::ZipCodes]
    #   A SwissMatch::ZipCodes collection with all SwissMatch::ZipCode objects having the given name.
    def by_name(name)
      @by_name ||= @zip_codes.each_with_object({}) { |zip_code, hash|
        (zip_code.names + zip_code.names_short).map(&:to_s).uniq.each do |name|
          hash[name] ||= []
          hash[name] << zip_code
        end
      }
      ZipCodes.new(@by_name[name] || [])
    end

    # @return [Integer] The number of SwissMatch::ZipCode objects in this collection.
    def size
      @zip_codes.size
    end

    # @return [Array<SwissMatch::ZipCode>]
    #   A SwissMatch::ZipCodes collection with all SwissMatch::ZipCode objects in this SwissMatch::ZipCodes.
    def to_a
      @zip_codes.dup
    end

    # @return [true, false] Whether this zip code collection contains any zip codes.
    def empty?
      @zip_codes.size.zero?
    end
    alias blank? empty?

    # @private
    # @see Object#inspect
    def inspect
      sprintf "\#<%s:%x size: %d>", self.class, object_id>>1, size
    end

  private
    def by_code_lookup_table
      @by_code ||= @zip_codes.group_by { |c| c.code }
    end

    def by_full_code_lookup_table
      @by_full_code ||= Hash[@zip_codes.map { |c| [c.full_code, c] }]
    end

    def by_code_and_name_lookup_table
      @by_code_and_name ||= Hash[@zip_codes.flat_map { |c|
        (c.names + c.names_short).map(&:to_s).uniq.map { |name| [[c.code, name], c] }
      }]
    end
  end
end
