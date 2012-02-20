# encoding: utf-8



require 'date'
require 'swissmatch/ruby'
require 'swissmatch/canton'
require 'swissmatch/cantons'
require 'swissmatch/community'
require 'swissmatch/communities'
require 'swissmatch/datafiles'
require 'swissmatch/version'
require 'swissmatch/zipcode'
require 'swissmatch/zipcodes'



# SwissMatch
# Deal with swiss zip codes, cities, communities and cantons.
#
# Notice that all strings passed to SwissMatch are expected to be utf-8. All strings
# returned by SwissMatch are also in utf-8.
#
# @example Load the data
#     require 'swissmatch'
#     SwissMatch.load
#     # alternatively, just require 'swissmatch/autoload'
#
# @example Get the ONRP for a given zip-code + city
#     require 'swissmatch/autoload'
#     SwissMatch.zip_code(8000, 'Zürich').ordering_number # => 
module SwissMatch
  @data             = nil

  class <<self
    # @return [SwissMatch::DataFiles] The data source used
    attr_reader :data
  end

  # @param [String, Integer] code_or_name
  #   Either the 4 digit zip code as Integer or String, or the city name as a String in
  #   utf-8.
  #
  # @return [Array<SwissMatch::ZipCode>]
  #   A list of zip codes with the given code or name.
  def self.zip_codes(code_or_name)
    case code_or_name
      when Integer, /\A\d{4}\z/
        @data.zip_codes.by_code(code_or_name.to_i)
      when String
        @data.zip_codes.by_name(code_or_name)
      else
        raise ArgumentError, "Invalid argument, must be a ZipCode#code (Integer or String) or ZipCode#name (String)"
    end
  end

  # @param [String, Integer] code
  #   The 4 digit zip code as Integer or String
  # @param [String, Integer] city_or_add_on
  #   Either the 2 digit zip-code add-on as string or integer, or the city name as a
  #   String in utf-8.
  #
  # @return [Array<SwissMatch::ZipCode>]
  #   The zip codes with the given code and the given add-on or name.
  def self.zip_code(code, city_or_add_on)
    case second
      when Integer, /\A\d\d\z/
        @data.zip_codes.by_code_and_add_on(code.to_i, city_or_add_on.to_i)
      when String
        @data.zip_codes.by_code_and_name(code.to_i, city_or_add_on)
      else
        raise ArgumentError, "Invalid second argument, must be nil, ZipCode#add_on or ZipCode#name"
    end
  end

  # @param [String] name
  #   The name for which to return matching zip codes
  #
  # @return [Array<SwissMatch::ZipCode>]
  #   Zip codes whose name equals the given name
  def self.city(name)
    @data.zip_codes.by_name(name)
  end

  # @param [String, Integer] code
  #   The 4 digit zip code
  # @param [nil, Array<Integer>] only_types
  #   An array of zip code types (see ZipCode#type) which the returned zip codes must match.
  # @param [nil, Symbol] locale
  #   Return the names in the given locale, defaults to nil/:native (nil and :native are
  #   treated the same and will return the native names)
  #
  # @return [Array<String>]
  #   A list of unique names matching the parameters (4 digit code, type, locale).
  def self.cities_for_zip_code(code, only_types=nil, locale=nil)
    codes = @data.zip_codes.by_code(code.to_i)
    return [] unless codes
    codes = codes.select { |code| only_types.include?(code.type) } if only_types
    names = case locale
      when :native,nil then codes.map(&:name)
      when :de then codes.map(&:name_de)
      when :fr then codes.map(&:name_fr)
      when :it then codes.map(&:name_it)
      when :rt then codes.map(&:name_rt)
      else raise ArgumentError, "Invalid locale #{locale}"
    end

    names.uniq
  end

  def self.load(data_source=nil)
    @data = data_source || DataFiles.new
    @data.load!
  end

  # @private
  # Used to transliterate city names
  Transliteration1 = {
    "à" => "a",
    "â" => "a",
    "ä" => "a",
    "è" => "e",
    "é" => "e",
    "ê" => "e",
    "ë" => "e",
    "ì" => "i",
    "î" => "i",
    "ï" => "i",
    "ô" => "o",
    "ö" => "o",
    "ù" => "u",
    "ü" => "u",
  }

  # @private
  # Used to transliterate city names
  Transliteration2 = Transliteration1.merge({
    "ä" => "ae",
    "ö" => "oe",
    "ü" => "ue",
  })

  # @private
  # Used to transliterate city names
  TransMatch1 = /#{Transliteration1.keys.map { |k| Regexp.escape(k) }.join("|")}/

  # @private
  # Used to transliterate city names
  TransMatch2 = /#{Transliteration2.keys.map { |k| Regexp.escape(k) }.join("|")}/

  # @private
  # Used to transliterate city names
  def self.transliterate1(word)
    word.gsub(TransMatch1, Transliteration1).delete("^ A-Za-z").downcase
  end

  # @private
  # Used to transliterate city names
  def self.transliterate2(word)
    word.gsub(TransMatch2, Transliteration2).delete("^ A-Za-z").downcase
  end
end
