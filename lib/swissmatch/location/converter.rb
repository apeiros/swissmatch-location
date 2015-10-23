module SwissMatch
  module Location

    # SwissMatch::Location::Converter
    #
    # Converts the files supplied by post.ch and bfs.admin.ch into a single
    # binary file which is faster to load
    #
    # Format:
    #   Byte 0...4: PostMatch master file date, in Date.jd format
    #   Byte 4...8: PostMach master file random code
    #   Byte 8...18: zip1_count, zip2_count, community1_count, community2_count, district_count; packed with N*
    #   Byte 18...34: bytesizes of int1_columns, int2_columns, int4_columns and text_columns
    #   Byte 34...-1: int1_columns + int2_columns + int4_columns + text_columns
    #   
    #   int1_columns: packed with C* the columns
    #   * zip1_type
    #   * zip1_addon
    #   * zip1_language
    #   * zip1_language_alternative
    #   * zip2_region
    #   * zip2_type
    #   * zip2_lang
    #   * com2_PLZZ
    #
    #   int2_columns: packed with n* the columns
    #   * zip1_onrp
    #   * zip1_code
    #   * zip1_delivery_by
    #   * zip1_largest_community_number
    #   * zip2_onrp
    #   * com1_bfsnr
    #   * com1_agglomeration
    #   * com2_GDENR
    #   * com2_PLZ4
    #   * district_GDEBZNR
    #
    #   int4_columns: packed with N* the columns
    #   * zip1_valid_from
    #
    #   text_columns: joined with \x1f
    #   * zip1_name_short
    #   * zip1_name
    #   * zip1_canton
    #   * zip2_short
    #   * zip2_name
    #   * com1_name
    #   * com1_canton
    #   * district_GDEKT
    #   * district_GDEBZNA
    #
    class Converter
      def initialize(match_path, districts_path=nil, communities_path=nil)
        @match_path       = match_path
        @districts_path   = districts_path || gem_districts_path
        @communities_path = communities_path || gem_communities_path
        @data             = nil
      end

      def gem_data_path
        data_directory = File.expand_path('../../../../data/swissmatch-location', __FILE__)
        data_directory = Gem.datadir 'swissmatch-location' if defined?(Gem) && !File.directory?(data_directory)

        data_directory
      end

      def gem_districts_path
        Dir.enum_for(:glob, "#{gem_data_path}/districts_*.csv").sort.last
      end

      def gem_communities_path
        Dir.enum_for(:glob, "#{gem_data_path}/communities_*.csv").sort.last
      end

      def generate_expression(size, separator, terminator)
        /^#{Array.new(size) { "([^#{separator}]*)" }.join(eval("'#{separator}'"))}#{terminator}/
      end

      def convert
        match_data       = File.read(@match_path, encoding: Encoding::Windows_1252).encode(Encoding::UTF_8)
        districts_data   = File.read(@districts_path, encoding: Encoding::Windows_1252).encode(Encoding::UTF_8)
        communities_data = File.read(@communities_path, encoding: Encoding::Windows_1252).encode(Encoding::UTF_8)

        r_base        = generate_expression(3, ';', '\r\n')
        r_zip_1       = generate_expression(16, ';', '\r\n')
        r_zip_2       = generate_expression(7, ';', '\r\n')
        r_community1  = generate_expression(5, ';', '\r\n')
        r_community2  = generate_expression(10, ',', '(?:\n|\z)')
        r_district    = generate_expression(3, ',', '\n')

        start_zip1 = match_data.index(/^01/)
        start_zip2 = match_data.index(/^02/, start_zip1)
        start_com  = match_data.index(/^03/, start_zip2)
        end_com    = match_data.index(/^04/, start_com)

        base      = match_data[0...start_zip1].scan(r_base).first
        zip1      = match_data[start_zip1...start_zip2].scan(r_zip_1); zip1.size
        zip2      = match_data[start_zip2...start_com].scan(r_zip_2); zip2.size
        com1      = match_data[start_com...end_com].scan(r_community1); com1.size
        com2      = communities_data.scan(r_community2); com2.size
        districts = districts_data.scan(r_district); districts.size

        zip1_columns = zip1.transpose; 0
        zip2_columns = zip2.transpose; 0
        com1_columns  = com1.transpose; 0
        com2_columns  = com2.transpose; 0
        dist_columns  = districts.transpose; 0

        int1_columns = (
          zip1_columns.values_at(3,5,10,11).flatten+
          zip2_columns.values_at(2,3,4).flatten+
          com2_columns[8]
        ).map(&:to_i).pack("C*")

        int2_columns = (
          zip1_columns.values_at(1,4,12,2).flatten+
          zip2_columns[1]+
          com1_columns.values_at(1,4).flatten+
          com2_columns[4]+
          com2_columns[7]+
          dist_columns[1]
        ).map(&:to_i).pack("n*")

        int4_columns = (
          zip1_columns[13].map { |date| Date.civil(*date.match(/^(\d{4})(\d\d)(\d\d)$/).captures.map(&:to_i)).jd }
        ).pack("N*")

        text_columns = (
          zip1_columns.values_at(7,8,9).flatten+
          zip2_columns[5]+
          zip2_columns[6]+
          com1_columns[2]+
          com1_columns[3]+
          dist_columns[0]+
          dist_columns[2]
        ).join("\x1f").force_encoding(Encoding::BINARY)

        @data =
          [Date.civil(*base[1].match(/^(\d{4})(\d\d)(\d\d)$/).captures.map(&:to_i)).jd, base[2].to_i].pack("NN")+
          [zip1.size, zip2.size, com1.size, com2.size, districts.size].pack("n*")+
          [int1_columns.bytesize, int2_columns.bytesize, int4_columns.bytesize, text_columns.bytesize].pack("N*")+
          int1_columns+
          int2_columns+
          int4_columns+
          text_columns

        self
      end

      def write(path)
        File.write(path, @data, encoding: Encoding::BINARY)
      end
    end
  end
end
