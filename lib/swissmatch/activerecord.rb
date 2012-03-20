# encoding: utf-8



require 'swissmatch'
require 'active_record'



module SwissMatch
  module ActiveRecord
    LanguageToCode = {
      :de => 1,
      :fr => 2,
      :it => 3,
      :rt => 4,
    }
    CodeToLanguage = LanguageToCode.invert

    def self.connect_from_config(config_file, environment=nil)
      config = YAML.load_file(config_file)
      config = config[environment] if config[environment]
      config = Hash[config.map { |k,v| [k.to_sym, v] }]
      ::ActiveRecord::Base.establish_connection(config)
    end

    def self.delete_all
      SwissMatch::ActiveRecord::ZipCodeName.delete_all
      SwissMatch::ActiveRecord::ZipCode.delete_all
      SwissMatch::ActiveRecord::Community.delete_all
      SwissMatch::ActiveRecord::Canton.delete_all
    end

    def self.cursor_hidden(io=$stdout)
      io.printf "\e[?25l"
      io.flush
      yield
    ensure
      io.printf "\e[?25h"
      io.flush
    end

    def self.print_progress(progress, total, width=80, io=$stdout)
      bar_width = width-8
      percent   = progress.fdiv(total)
      filled    = (percent*bar_width).round
      empty     = bar_width - filled
      io.printf "\r\e[1m %5.1f%%\e[0m \e[44m%*s\e[46m%*s\e[0m", percent*100, filled, '', empty, ''
      io.flush
    end

    def self.seed(data_source=SwissMatch.data)
      canton2id     = {}
      total         = data_source.cantons.size +
                      data_source.communities.size +
                      data_source.zip_codes.size*2 +
                      10
      progress      = 0

      cursor_hidden do
        print_progress(progress, total)

        ::ActiveRecord::Base.transaction do
          delete_all
          print_progress(progress+=10, total)

          data_source.cantons.each do |canton|
            canton2id[canton.license_tag] = SwissMatch::ActiveRecord::Canton.create!(canton.to_hash, :without_protection => true).id
            print_progress(progress+=1, total)
          end
          data_source.communities.partition do |community|
            hash                    = community.to_hash
            hash[:canton_id]        = canton2id[hash.delete(:canton)]
            hash[:agglomeration_id] = hash.delete(:agglomeration)
            SwissMatch::ActiveRecord::Community.create!(hash, :without_protection => true)
            print_progress(progress+=1, total)
          end
          self_delivered, others = data_source.zip_codes.partition { |code| code.delivery_by.nil? || code.delivery_by == code }
          process_code = proc do |zip_code|
            hash                        = zip_code.to_hash
            hash[:id]                   = hash.delete(:ordering_number)
            hash[:delivery_by_id]       = hash.delete(:delivery_by)
            hash[:canton_id]            = canton2id[hash.delete(:canton)]
            hash[:language]             = LanguageToCode[hash.delete(:language)]
            hash[:language_alternative] = LanguageToCode[hash.delete(:language_alternative)]
            hash[:community_id]         = hash.delete(:community)
            hash.update(
              :suggested_name_de => zip_code.suggested_name(:de),
              :suggested_name_fr => zip_code.suggested_name(:fr),
              :suggested_name_it => zip_code.suggested_name(:it),
              :suggested_name_rt => zip_code.suggested_name(:rt)
            )
            hash.delete(:name_short) # not used

            # FIXME: work around, should be replaced by a proper mechanism
            hash.delete(:valid_from)
            hash.delete(:valid_until)
            hash[:active]               = true

            SwissMatch::ActiveRecord::ZipCode.create!(hash, :without_protection => true)
            zip_code.names.each do |name|
              hash                = name.to_hash
              hash[:language]     = LanguageToCode[hash.delete(:language)]
              hash[:zip_code_id]  = zip_code.ordering_number
              hash[:designation]  = 2 # designation of type 3 is not currently in the system
              SwissMatch::ActiveRecord::ZipCodeName.create!(hash, :without_protection => true)
            end
            print_progress(progress+=2, total)
          end

          self_delivered.each(&process_code)
          others.each(&process_code)
        end
      end
      puts "","Done"
    end

    def self.update(data_source=SwissMatch.data)
    end

    class Migration < ::ActiveRecord::Migration
      def down
        try_drop_table :swissmatch_zip_code_names
        try_drop_table :swissmatch_zip_codes
        try_drop_table :swissmatch_communities
        try_drop_table :swissmatch_cantons
        try_execute "No view support, did not drop view swissmatch_named_zip_codes", "DROP VIEW swissmatch_named_zip_codes"
      end

      def try_drop_table(name)
        drop_table name
      rescue => e
        warn "Could not drop #{name}: #{e}"
      end

      def try_execute(failure_message, *sqls)
        sqls.each do |sql_statements|
          sql_statements.split(/;\n/).each do |sql_statement|
            execute(sql_statement.chomp(';'))
          end
        end
      rescue => e
        warn "#{failure_message} (#{e})"
      end

      def up
        create_table :swissmatch_cantons, :comment => 'All swiss cantons as needed by swiss posts MAT[CH], includes the non-cantons DE and IT.' do |t|
          t.integer :id,          :null => false, :limit => 6,  :comment => 'A unique ID, unrelated to the swiss postal service data.'
          t.string  :license_tag, :null => false, :limit => 2,  :comment => 'The two letter abbreviation of the cantons name as used on license plates.'
          t.string  :name,        :null => false, :limit => 32, :comment => 'The canonical name of the canton.'
          t.string  :name_de,     :null => false, :limit => 32, :comment => 'The name of the canton in german.'
          t.string  :name_fr,     :null => false, :limit => 32, :comment => 'The name of the canton in french.'
          t.string  :name_it,     :null => false, :limit => 32, :comment => 'The name of the canton in italian.'
          t.string  :name_rt,     :null => false, :limit => 32, :comment => 'The name of the canton in rheto-romanic.'

          t.timestamps
        end

        create_table :swissmatch_communities, :comment => 'The swiss communities as per plz_c file from the swiss posts MAT[CH].' do |t|
          t.integer  :id,                :null => false, :limit => 6,  :comment => 'A unique, never recycled identification number. Also known as BFSNR.'
          t.string   :name,              :null => false, :limit => 32, :comment => 'The canonical name of the community.'
          t.integer  :canton_id,         :null => false, :limit => 6,  :comment => 'The canton this community belongs to.'
          t.integer  :agglomeration_id,  :null => true,  :limit => 6,  :comment => 'The community this community is considered to be an agglomeration of. Note that a main community will reference itself.'

          t.timestamps
        end

        create_table :swissmatch_zip_codes, :comment => 'The swiss zip codes as per plz_p1 and plz_p2 files from the swiss posts MAT[CH].' do |t|
          t.integer :id,                    :null => false, :limit => 6,  :comment => 'The postal ordering number, also known as ONRP. Unique and never recycled.'
          t.integer :type,                  :null => false, :limit => 16, :comment => 'The type of the entry. One of 10 (Domizil- und Fachadressen), 20 (Nur Domiziladressen), 30 (Nur Fach-PLZ), 40 (Firmen-PLZ) or 80 (Postinterne PLZ).'
          t.integer :code,                  :null => false, :limit => 16, :comment => 'The 4 digit numeric zip code. Note that the 4 digit code alone does not uniquely identify a zip code record.'
          t.integer :add_on,                :null => false, :limit => 16, :comment => 'The 2 digit numeric code addition, to distinguish zip codes with the same 4 digit code.'
          t.integer :canton_id,             :null => false, :limit => 6,  :comment => 'The canton this zip code belongs to.'
          t.string  :name,                  :null => false, :limit => 27, :comment => 'The canonical name (city) that belongs to this zip code.'
          t.string  :suggested_name_de,     :null => false, :limit => 27, :comment => 'The suggested name of the zip code (city) for german.'
          t.string  :suggested_name_fr,     :null => false, :limit => 27, :comment => 'The suggested name of the zip code (city) for french.'
          t.string  :suggested_name_it,     :null => false, :limit => 27, :comment => 'The suggested name of the zip code (city) for italian.'
          t.string  :suggested_name_rt,     :null => false, :limit => 27, :comment => 'The suggested name of the zip code (city) for rheto-romanic.'
          t.integer :language,              :null => false, :limit => 2,  :comment => 'The main language in the area of this zip code. 1 = de, 2 = fr, 3 = it, 4 = rt.'
          t.integer :language_alternative,  :null => true,  :limit => 2,  :comment => 'The second most used language in the area of this zip code. 1 = de, 2 = fr, 3 = it, 4 = rt.'
          t.boolean :sortfile_member,       :null => true,                :comment => 'Whether this ZipCode instance is included in the MAT[CH]sort sortfile.'
          t.integer :delivery_by_id,        :null => true,  :limit => 6,  :comment => 'By which postal office delivery of letters is usually taken care of.'
          t.integer :community_id,          :null => false, :limit => 6,  :comment => 'The community this zip code belongs to.'
          t.boolean :active,                :null => false,               :comment => 'Whether this record is currently active.'
#           t.date    :valid_from,                          :comment => 'The date from which on this zip code starts to be in use.'
#           t.date    :valid_until,                         :comment => '[CURRENTLY NOT USED] The date until which this zip code is in use.'

          t.timestamps
        end
        add_index :swissmatch_zip_codes, [:code]

        create_table :swissmatch_zip_code_names, :comment => 'Contains all primary and alternative names of zip codes.' do |t|
          t.integer :id,              :null => false, :limit => 6,  :comment => 'An internal ID.'
          t.integer :zip_code_id,     :null => false, :limit => 6,  :comment => 'The postal ordering number to which this name belongs.'
          t.string  :name,            :null => false, :limit => 27, :comment => 'The name (city) that belongs to this zip code. At a maximum 27 characters long.'
          t.integer :language,        :null => false, :limit => 2,  :comment => 'The main language in the area of this zip code. 1 = de, 2 = fr, 3 = it, 4 = rt.'
          t.integer :sequence_number, :null => false, :limit => 3,  :comment => 'The sequence number of names unique for a single ONRP, a deleted sequence number is never reused.'
          t.integer :designation,     :null => false, :limit => 2,  :comment => 'The way this name is to be used. Valid values are 2 or 3, 2 2 means this name can be used instead of the zip_code name, 3 means this can be used in addition to the zip_code name.'

          t.timestamps
        end
        add_index :swissmatch_zip_code_names, [:name]

        # not every db supports views
        try_execute "No view support, did not create view swissmatch_named_zip_codes", <<-SQL
          CREATE VIEW swissmatch_named_zip_codes AS
            SELECT
              z.id                    zip_code_id,
              z.type                  type,
              n.name                  name,
              n.language              name_language,
              n.sequence_number       sequence_number,
              z.code                  code,
              z.add_on                add_on,
              z.canton_id             canton_id,
              z.language              language,
              z.language_alternative  language_alternative,
              z.sortfile_member       sortfile_member,
              z.delivery_by_id        delivery_by_id,
              z.community_id          community_id,
              z.active                active
            FROM swissmatch_zip_codes z
            JOIN swissmatch_zip_code_names n ON n.zip_code_id = z.id
            WHERE n.designation = 2
        SQL

        # not every db supports comments
        try_execute "No comment support, did comment on swissmatch_named_zip_codes", <<-SQL
          COMMENT ON TABLE swissmatch_named_zip_codes IS 'Lists all zip-code/name combinations, an ONRP can occur multiple times.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.zip_code_id IS           'The ONRP of the zip code (swissmatch_zip_codes.id)';
          COMMENT ON COLUMN swissmatch_named_zip_codes.type IS                  'The type of the entry. One of 10 (Domizil- und Fachadressen), 20 (Nur Domiziladressen), 30 (Nur Fach-PLZ), 40 (Firmen-PLZ) or 80 (Postinterne PLZ).';
          COMMENT ON COLUMN swissmatch_named_zip_codes.zip_code_id IS           'The postal ordering number to which this name belongs.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.name IS                  'The name (city) that belongs to this zip code. At a maximum 27 characters long.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.name_language IS         'The main language in the area of this zip code. 1 = de, 2 = fr, 3 = it, 4 = rt.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.sequence_number IS       'The sequence number of names unique for a single ONRP, a deleted sequence number is never reused.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.code IS                  'The 4 digit numeric zip code. Note that the 4 digit code alone does not uniquely identify a zip code record.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.add_on IS                'The 2 digit numeric code addition, to distinguish zip codes with the same 4 digit code.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.canton_id IS             'The canton this zip code belongs to.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.name IS                  'The name (city) that belongs to this zip code. At a maximum 27 characters long.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.language IS              'The main language in the area of this zip code. 1 = de, 2 = fr, 3 = it, 4 = rt.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.language_alternative IS  'The second most used language in the area of this zip code. 1 = de, 2 = fr, 3 = it, 4 = rt.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.sortfile_member IS       'Whether this ZipCode instance is included in the MAT[CH]sort sortfile.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.delivery_by_id IS        'By which postal office delivery of letters is usually taken care of.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.community_id IS          'The community this zip code belongs to.';
          COMMENT ON COLUMN swissmatch_named_zip_codes.active IS                'Whether this record is currently active.';
        SQL

        # not every db supports foreign key constraints, and maybe there are also syntax differences,
        try_execute "No foreign key support, did not create foreign key constraints", <<-SQL1, <<-SQL2, <<-SQL3
          ALTER TABLE swissmatch_communities
            ADD CONSTRAINT fk_sm_com_0001 FOREIGN KEY (canton_id) REFERENCES swissmatch_cantons(id)
            ADD CONSTRAINT fk_sm_com_0002 FOREIGN KEY (agglomeration_id) REFERENCES swissmatch_communities(id)
        SQL1
          ALTER TABLE swissmatch_zip_codes
            ADD CONSTRAINT fk_sm_zip_0001 FOREIGN KEY (canton_id) REFERENCES swissmatch_cantons(id)
            ADD CONSTRAINT fk_sm_zip_0002 FOREIGN KEY (community_id) REFERENCES swissmatch_communities(id)
            ADD CONSTRAINT fk_sm_zip_0003 FOREIGN KEY (delivery_by_id) REFERENCES swissmatch_zip_codes(id)
        SQL2
          ALTER TABLE swissmatch_zip_code_names
            ADD CONSTRAINT fk_sm_nam_0001 FOREIGN KEY (zip_code_id) REFERENCES swissmatch_zip_codes(id)
        SQL3
      end
    end

    class ZipCode < ::ActiveRecord::Base
      self.table_name         = "swissmatch_zip_codes"
      self.inheritance_column = "no_sti_in_this_model" # set it to something unused, so 'type' can be used as column name

      alias_attribute :ordering_number, :id

      belongs_to :canton,      :class_name => 'SwissMatch::ActiveRecord::Canton'
      belongs_to :community,   :class_name => 'SwissMatch::ActiveRecord::Community'
      belongs_to :delivery_by, :class_name => 'SwissMatch::ActiveRecord::ZipCode'
      has_many   :delivers,    :class_name => 'SwissMatch::ActiveRecord::ZipCode', :foreign_key => 'delivery_by_id'
      has_many   :names,       :class_name => 'SwissMatch::ActiveRecord::ZipCodeName'
    end
    class ZipCodeName < ::ActiveRecord::Base
      self.table_name         = "swissmatch_zip_code_names"

      belongs_to :zip_code,    :class_name => 'SwissMatch::ActiveRecord::ZipCode'
    end
    class Community < ::ActiveRecord::Base
      self.table_name = "swissmatch_communities"

      alias_attribute :community_number, :id

      belongs_to :canton,         :class_name => 'SwissMatch::ActiveRecord::Canton'
      belongs_to :agglomeration,  :class_name => 'SwissMatch::ActiveRecord::Community'
      has_many   :zip_codes,      :class_name => 'SwissMatch::ActiveRecord::ZipCode'
    end
    class Canton < ::ActiveRecord::Base
      self.table_name = "swissmatch_cantons"

      has_many :zip_codes,    :class_name => 'SwissMatch::ActiveRecord::ZipCode'
      has_many :communities,  :class_name => 'SwissMatch::ActiveRecord::Community'
    end
  end
end
