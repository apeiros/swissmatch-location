# encoding: utf-8



require 'autocompletion'



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

    def reset!
      @by_ordering_number = nil
      @by_code            = nil
      @by_full_code       = nil
      @by_code_and_name   = nil
      @by_name            = nil
      @autocomplete       = nil

      self
    end

    def replace(other, reset=true)
      case other
        when SwissMatch::ZipCodes
          @zip_codes.replace(other.instance_variable_get(:@zip_codes))
        when Array
          @zip_codes.replace(other)
        else
          raise ArgumentError, "Expected an array or a SwissMatch::ZipCodes, but got #{other.class}"
      end
      reset! if reset

      self
    end

    def [](key)
      case key
        when 100_000..999_999, /\A(\d{4})(\d\d)\z/
          $1 ? by_code_and_add_on($1.to_i, $2.to_i) : by_code_and_add_on(*key.divmod(100))
        when 0..9999, /\A\d{4}\z/
          by_code(key.to_i)
        when String
          by_name(key)
        else
          raise ArgumentError, "Expected a string or an integer between 1000 and 999_999"
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

    def active(date=Date.today, &block)
      ZipCodes.new(@zip_codes.select { |zip_code| zip_code.in_use?(date) })
    end

    def inactive(date=Date.today, &block)
      ZipCodes.new(@zip_codes.reject { |zip_code| zip_code.in_use?(date) })
    end

    # WARNING: the autocompletion API is not yet final
    def autocomplete(string)
      @autocomplete ||= AutoCompletion.map(@zip_codes) { |zip_code|
        zip_code.transliterated_names
      }

      t1 = @autocomplete.complete(*SwissMatch.transliterate1(string).split(" "))
      t2 = @autocomplete.complete(*SwissMatch.transliterate2(string).split(" "))

      t1 | t2
    end

    def with_type(*types)
      ZipCodes.new(@zip_codes.select { |zip_code| types.include?(zip_code.type) })
    end

    def without_type(*types)
      ZipCodes.new(@zip_codes.reject { |zip_code| types.include?(zip_code.type) })
    end

    # @return [SwissMatch::ZipCode] 
    #   The SwissMatch::ZipCode with the given ordering number (ONRP).
    def by_ordering_number(onrp)
      @by_ordering_number ||= Hash[@zip_codes.map { |c| [c.ordering_number, c] }]
      @by_ordering_number[onrp]
    end

    # @return [SwissMatch::ZipCodes]
    #   An array with all SwissMatch::ZipCode objects having the given 4 digit code.
    def by_code(code)
      @by_code ||= @zip_codes.group_by { |c| c.code }
      ZipCodes.new(@by_code[code] || [])
    end

    # @return [SwissMatch::ZipCode]
    #   The SwissMatch::ZipCode with the given 4 digit code and given 2 digit code add-on.
    def by_code_and_add_on(code, add_on)
      @by_full_code ||= Hash[@zip_codes.map { |c| [c.full_code, c] }]
      @by_full_code[code*100+add_on]
    end

    # @return [SwissMatch::ZipCode]
    #   The SwissMatch::ZipCode with the given 4 digit code and name in any language.
    def by_code_and_name(code, name)
      @by_code_and_name ||= Hash[@zip_codes.flat_map { |c|
        c.names.map { |name| [[c.code, name], c] }
      }]
      @by_code_and_name[[code,name]]
    end

    # @return [SwissMatch::ZipCodes]
    #   An array with all SwissMatch::ZipCode objects having the given name.
    def by_name(name)
      @by_name ||= @zip_codes.each_with_object({}) { |zip_code, hash|
        zip_code.names.map(&:to_s).uniq.each do |name|
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
    #   An Array with all SwissMatch::ZipCode objects in this SwissMatch::ZipCodes.
    def to_a
      @zip_codes.dup
    end
  end
end
