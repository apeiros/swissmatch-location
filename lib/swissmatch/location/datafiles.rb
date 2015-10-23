# encoding: utf-8



require 'swissmatch/loaderror'
require 'swissmatch/name'
require 'swissmatch/canton'
require 'swissmatch/cantons'
require 'swissmatch/district'
require 'swissmatch/districts'
require 'swissmatch/community'
require 'swissmatch/communities'
require 'swissmatch/zipcode'
require 'swissmatch/zipcodes'
require 'swissmatch/location/ruby'



module SwissMatch
  module Location

    # SwissMatch::Location::DataFiles
    #
    # Deals with retrieving and updating the files provided by the swiss postal service,
    # and loading the data from them.
    #
    # @todo
    #   The current handling of the urls is not clean. I don't know yet how the urls will
    #   change over iterations.
    class DataFiles

      # Used to convert numerical language codes to symbols
      LanguageCodes = [nil, :de, :fr, :it, :rt]

      # The data of all cantons
      # @private
      AllCantons = Cantons.new([
        Canton.new("AG", "Aargau",                    "Aargau",                   "Argovie",                      "Argovia",                  "Argovia"),
        Canton.new("AI", "Appenzell Innerrhoden",     "Appenzell Innerrhoden",    "Appenzell Rhodes-Intérieures", "Appenzello Interno",       "Appenzell Dadens"),
        Canton.new("AR", "Appenzell Ausserrhoden",    "Appenzell Ausserrhoden",   "Appenzell Rhodes-Extérieures", "Appenzello Esterno",       "Appenzell Dadora"),
        Canton.new("BE", "Bern",                      "Bern",                     "Berne",                        "Berna",                    "Berna"),
        Canton.new("BL", "Basel-Landschaft",          "Basel-Landschaft",         "Bâle-Campagne",                "Basilea Campagna",         "Basilea-Champagna"),
        Canton.new("BS", "Basel-Stadt",               "Basel-Stadt",              "Bâle-Ville",                   "Basilea Città",            "Basilea-Citad"),
        Canton.new("FR", "Freiburg",                  "Fribourg",                 "Fribourg",                     "Friburgo",                 "Friburg"),
        Canton.new("GE", "Genève",                    "Genf",                     "Genève",                       "Ginevra",                  "Genevra"),
        Canton.new("GL", "Glarus",                    "Glarus",                   "Glaris",                       "Glarona",                  "Glaruna"),
        Canton.new("GR", "Graubünden",                "Graubünden",               "Grisons",                      "Grigioni",                 "Grischun"),
        Canton.new("JU", "Jura",                      "Jura",                     "Jura",                         "Giura",                    "Giura"),
        Canton.new("LU", "Luzern",                    "Luzern",                   "Lucerne",                      "Lucerna",                  "Lucerna"),
        Canton.new("NE", "Neuchâtel",                 "Neuenburg",                "Neuchâtel",                    "Neuchâtel",                "Neuchâtel"),
        Canton.new("NW", "Nidwalden",                 "Nidwalden",                "Nidwald",                      "Nidvaldo",                 "Sutsilvania"),
        Canton.new("OW", "Obwalden",                  "Obwalden",                 "Obwald",                       "Obvaldo",                  "Sursilvania"),
        Canton.new("SG", "St. Gallen",                "St. Gallen",               "Saint-Gall",                   "San Gallo",                "Son Gagl"),
        Canton.new("SH", "Schaffhausen",              "Schaffhausen",             "Schaffhouse",                  "Sciaffusa",                "Schaffusa"),
        Canton.new("SO", "Solothurn",                 "Solothurn",                "Soleure",                      "Soletta",                  "Soloturn"),
        Canton.new("SZ", "Schwyz",                    "Schwyz",                   "Schwytz",                      "Svitto",                   "Sviz"),
        Canton.new("TG", "Thurgau",                   "Thurgau",                  "Thurgovie",                    "Turgovia",                 "Turgovia"),
        Canton.new("TI", "Ticino",                    "Tessin",                   "Tessin",                       "Ticino",                   "Tessin"),
        Canton.new("UR", "Uri",                       "Uri",                      "Uri",                          "Uri",                      "Uri"),
        Canton.new("VD", "Vaud",                      "Waadt",                    "Vaud",                         "Vaud",                     "Vad"),
        Canton.new("VS", "Valais",                    "Wallis",                   "Valais",                       "Vallese",                  "Vallais"),
        Canton.new("ZG", "Zug",                       "Zug",                      "Zoug",                         "Zugo",                     "Zug"),
        Canton.new("ZH", "Zürich",                    "Zürich",                   "Zurich",                       "Zurigo",                   "Turitg"),
        Canton.new("FL", "Fürstentum Liechtenstein",  "Fürstentum Liechtenstein", "Liechtenstein",                "Liechtenstein",            "Liechtenstein"),
        Canton.new("DE", "Deutschland",               "Deutschland",              "Allemagne",                    "Germania",                 "Germania"),
        Canton.new("IT", "Italien",                   "Italien",                  "Italie",                       "Italia",                   "Italia"),
      ])

      def self.empty
        data = new
        data.load_empty!

        data
      end

      # @return [Date]
      #   The date from when the data from the swiss post master data file
      #   starts to be valid
      attr_reader :date

      # @return [Integer]
      #   The random code from the swiss post master data file
      attr_reader :random_code

      # The directory in which the post mat[ch] files reside
      attr_accessor :data_directory

      # @return [SwissMatch::Cantons] The loaded swiss cantons
      attr_reader :cantons

      # @return [SwissMatch::Districts] The loaded swiss districts
      attr_reader :districts

      # @return [SwissMatch::Communities] The loaded swiss communities
      attr_reader :communities

      # @return [SwissMatch::ZipCodes] The loaded swiss zip codes
      attr_reader :zip_codes

      # @return [Array<LoadError>] Errors that occurred while loading the data
      attr_reader :errors

      # @param [nil, String] data_directory
      #   The directory in which the post mat[ch] files reside
      def initialize(data_directory=nil)
        reset_errors!
        @loaded = false
        if data_directory then
          @data_directory = data_directory
        elsif ENV['SWISSMATCH_DATA'] then
          @data_directory = ENV['SWISSMATCH_DATA']
        else
          @data_directory  = File.expand_path('~/.swissmatch')
        end
      end

      # Resets the list of errors that were encountered during load
      # @return [self]
      def reset_errors!
        @errors = []
        self
      end

      def latest_binary_file
        Dir.enum_for(:glob, "#{@data_directory}/locations_*.binary").last
      end

      def load_empty!
        return if @loaded

        @loaded      = true
        @date        = Date.new(0)
        @random_code = 0
        @cantons     = AllCantons
        @districts   = Districts.new([])
        @communities = Communities.new([])
        @zip_codes   = ZipCodes.new([])
      end

      # Loads the data into this DataFiles instance
      #
      # @return [self]
      #   Returns self.
      def load!(file=nil)
        return if @loaded

        file ||= latest_binary_file

        raise LoadError.new("File #{file.inspect} not found or not readable", nil) unless file && File.readable?(file)

        data = File.read(file, encoding: Encoding::BINARY)
        date, random_code, zip1_count, zip2_count, com1_count, com2_count, district_count = *data[0,18].unpack("NNn*")
        int1_size, int2_size, int4_size, text_size = *data[18,16].unpack("N*")

        offset    = 34
        int1_cols = data[offset, int1_size].unpack("C*")
        int2_cols = data[offset+=int1_size, int2_size].unpack("n*")
        int4_cols = data[offset+=int2_size, int4_size].unpack("N*")
        text_cols = data[offset+=int4_size, text_size].force_encoding(Encoding::UTF_8).split("\x1f")

        offset                    = 0
        zip1_type                 = int1_cols[offset, zip1_count]
        zip1_addon                = int1_cols[offset += zip1_count, zip1_count]
        zip1_language             = int1_cols[offset += zip1_count, zip1_count]
        zip1_language_alternative = int1_cols[offset += zip1_count, zip1_count]
        zip2_region               = int1_cols[offset += zip1_count, zip2_count]
        zip2_type                 = int1_cols[offset += zip2_count, zip2_count]
        zip2_lang                 = int1_cols[offset += zip2_count, zip2_count]
        com2_PLZZ                 = int1_cols[offset += zip2_count, com2_count]

        offset                        = 0
        zip1_onrp                     = int2_cols[offset, zip1_count]
        zip1_code                     = int2_cols[offset += zip1_count, zip1_count]
        zip1_delivery_by              = int2_cols[offset += zip1_count, zip1_count]
        zip1_largest_community_number = int2_cols[offset += zip1_count, zip1_count]
        zip2_onrp                     = int2_cols[offset += zip1_count, zip2_count]
        com1_bfsnr                    = int2_cols[offset += zip2_count, com1_count]
        com1_agglomeration            = int2_cols[offset += com1_count, com1_count]
        com2_GDENR                    = int2_cols[offset += com1_count, com2_count]
        com2_PLZ4                     = int2_cols[offset += com2_count, com2_count]
        district_GDEBZNR              = int2_cols[offset += com2_count, district_count]

        zip1_valid_from = int4_cols

        offset           = 0
        zip1_name_short  = text_cols[offset, zip1_count]
        zip1_name        = text_cols[offset += zip1_count, zip1_count]
        zip1_canton      = text_cols[offset += zip1_count, zip1_count]
        zip2_short       = text_cols[offset += zip1_count, zip2_count]
        zip2_name        = text_cols[offset += zip2_count, zip2_count]
        com1_name        = text_cols[offset += zip2_count, com1_count]
        com1_canton      = text_cols[offset += com1_count, com1_count]
        district_GDEKT   = text_cols[offset += com1_count, district_count]
        district_GDEBZNA = text_cols[offset += district_count, district_count]

        zip1     = [
          zip1_onrp, zip1_type, zip1_canton, zip1_code, zip1_addon,
          zip1_delivery_by, zip1_language, zip1_language_alternative,
          zip1_name_short, zip1_name, zip1_largest_community_number,
          zip1_valid_from
        ].transpose
        zip2     = [zip2_onrp, zip2_region, zip2_type, zip2_lang, zip2_short, zip2_name].transpose
        com1     = [com1_bfsnr, com1_name, com1_canton, com1_agglomeration].transpose
        com2     = [com2_PLZ4, com2_PLZZ, com2_GDENR].transpose
        district = [district_GDEKT, district_GDEBZNR, district_GDEBZNA].transpose

        @date        = Date.jd(date)
        @random_code = random_code
        @cantons     = AllCantons
        @districts   = load_districts(district)
        @communities = load_communities(com1)
        @zip_codes   = load_zipcodes(zip1, zip2, com2)

        self
      end

      def load_districts(data)
        Districts.new(data.map { |data|
          District.new(*data, SwissMatch::Communities.new([]))
        })
      end

      # @return [SwissMatch::Communities]
      #   An instance of SwissMatch::Communities containing all communities defined by the
      #   files known to this DataFiles instance.
      def load_communities(data)
        temporary = []
        complete  = {}
        data.each do |bfsnr, name, canton, agglomeration|
          canton = @cantons.by_license_tag(canton)
          if agglomeration == bfsnr then
            complete[bfsnr] = Community.new(bfsnr, name, canton, :self)
          elsif agglomeration.zero? then
            complete[bfsnr] = Community.new(bfsnr, name, canton, nil)
          else
            temporary << [bfsnr, name, canton, agglomeration]
          end
        end
        temporary.each do |bfsnr, name, canton, agglomeration|
          community = complete[agglomeration]
          raise "Incomplete community referenced by #{bfsnr}: #{agglomeration}" unless agglomeration
          complete[bfsnr] = Community.new(bfsnr, name, canton, community)
        end

        Communities.new(complete.values)
      end

      # TODO: load all files, not just the most recent
      # TODO: calculate valid_until dates
      #
      # @return [SwissMatch::ZipCodes]
      #   An instance of SwissMatch::ZipCodes containing all zip codes defined by the
      #   files known to this DataFiles instance.
      def load_zipcodes(zip1_data, zip2_data, com2_data)
        community_mapping = Hash.new { |h,k| h[k] = [] }
        self_delivered    = []
        others            = []
        temporary         = {}

        com2_data.each do |*key, value|
          community_mapping[key] << value
        end

        zip1_data.each do |onrp, type, canton, code, addon, delivery_by, lang, lang_alt, name_short, name, largest_community_number, valid_from|
          delivery_by               = case delivery_by when 0 then nil; when onrp then :self; else delivery_by; end
          language                  = LanguageCodes[lang]
          language_alternative      = LanguageCodes[lang_alt]
          name_short                = Name.new(name_short, language)
          name                      = Name.new(name, language)

          # compact, because some communities already no longer exist, so by_community_numbers can
          # contain nils which must be removed
          community_numbers         = (community_mapping[[code, addon]] | [largest_community_number]).sort
          communities               = Communities.new(@communities.by_community_numbers(*community_numbers).compact)

          data                      = [
            onrp,                              # ordering_number
            type,                              # type
            code,
            addon,
            name,                              # name (official)
            [name],                            # names (official + alternative)
            name_short,                        # name_short (official)
            [name_short],                      # names_short (official + alternative)
            [],                                # PLZ2 type 3 short names (additional region names)
            [],                                # PLZ2 type 3 names (additional region names)
            cantons.by_license_tag(canton),    # canton
            language,
            language_alternative,
            false,                             # sortfile_member TODO: remove
            delivery_by,                       # delivery_by
            communities.by_community_number(largest_community_number),  # community_number
            communities,
            Date.jd(valid_from) # valid_from
          ]
          temporary[onrp] = data
          if :self == delivery_by then
            self_delivered << data
          else
            others << data
          end
        end

        zip2_data.each do |onrp, rn, type, lang, short, name|
          onrp      = onrp.to_i
          lang_code = lang.to_i
          language  = LanguageCodes[lang_code]
          entry     = temporary[onrp]
          if type == 2
            entry[5] << Name.new(name, language, rn.to_i)
            entry[7] << Name.new(short, language, rn.to_i)
          elsif type == 3
            entry[8] << Name.new(name, language, rn.to_i)
            entry[9] << Name.new(short, language, rn.to_i)
          end
        end

        self_delivered.each do |row|
          temporary[row[0]] = ZipCode.new(*row)
        end
        others.each do |row|
          if row[14] then
            raise "Delivery not found:\n#{row.inspect}" unless tmp = temporary[row[14]]
            if tmp.kind_of?(Array) then
              @errors << LoadError.new("Invalid reference: onrp #{row.at(0)} delivery by #{row.at(14)}", row)
              row[14] = nil
            else
              row[14] = tmp
            end
          end
          temporary[row[0]] = ZipCode.new(*row)
        end

        ZipCodes.new(temporary.values)
      end
    end
  end
end
