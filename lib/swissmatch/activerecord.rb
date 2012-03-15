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
                      data_source.zip_codes.size +
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

            # FIXME: work around, should be replaced by a proper mechanism
            hash.delete(:valid_from)
            hash.delete(:valid_until)
            hash[:active]               = true

            SwissMatch::ActiveRecord::ZipCode.create!(hash, :without_protection => true)
            print_progress(progress+=1, total)
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
        drop_table :swissmatch_zip_codes
        drop_table :swissmatch_communities
        drop_table :swissmatch_cantons
      end

      def up
        create_table :swissmatch_cantons, :comment => 'All swiss cantons as needed by swiss posts MAT[CH], includes the non-cantons DE and IT.' do |t|
          t.integer :id,          :limit => 6,  :comment => 'A unique ID, unrelated to the swiss postal service data.'
          t.string  :license_tag, :limit => 2,  :comment => 'The two letter abbreviation of the cantons name as used on license plates.'
          t.string  :name,        :limit => 32, :comment => 'The official name of the canton.'
          t.string  :name_de,     :limit => 32, :comment => 'The name of the canton in german.'
          t.string  :name_fr,     :limit => 32, :comment => 'The name of the canton in french.'
          t.string  :name_it,     :limit => 32, :comment => 'The name of the canton in italian.'
          t.string  :name_rt,     :limit => 32, :comment => 'The name of the canton in rheto-romanic.'

          t.timestamps
        end

        create_table :swissmatch_communities, :comment => 'The swiss communities as per plz_c file from the swiss posts MAT[CH].' do |t|
          t.integer  :id,                :limit => 6,  :comment => 'A unique, never recycled identification number. Also known as BFSNR.'
          t.string   :name,              :limit => 32, :comment => 'The official name of the community.'
          t.integer  :canton_id,         :limit => 6,  :comment => 'The canton this community belongs to.'
          t.integer  :agglomeration_id,  :limit => 6,  :comment => 'The community this community is considered to be an agglomeration of. Note that a main community will reference itself.'

          t.timestamps
        end

        create_table :swissmatch_zip_codes, :comment => 'The swiss zip codes as per plz_p1 and plz_p2 files from the swiss posts MAT[CH].' do |t|
          t.integer :id,                    :limit => 6,  :comment => 'The postal ordering number, also known as ONRP. Unique and never recycled.'
          t.integer :type,                  :limit => 16, :comment => 'The type of the entry. One of 10 (Domizil- und Fachadressen), 20 (Nur Domiziladressen), 30 (Nur Fach-PLZ), 40 (Firmen-PLZ) or 80 (Postinterne PLZ).'
          t.integer :code,                  :limit => 16, :comment => 'The 4 digit numeric zip code. Note that the 4 digit code alone does not uniquely identify a zip code record.'
          t.integer :add_on,                :limit => 16, :comment => 'The 2 digit numeric code addition, to distinguish zip codes with the same 4 digit code.'
          t.integer :canton_id,             :limit => 6,  :comment => 'The canton this zip code belongs to.'
          t.string  :name,                  :limit => 27, :comment => 'The name (city) that belongs to this zip code. At a maximum 27 characters long.'
          t.string  :name_de,               :limit => 27, :comment => 'The name (city) in german that belongs to this zip code. At a maximum 27 characters long.'
          t.string  :name_fr,               :limit => 27, :comment => 'The name (city) in french that belongs to this zip code. At a maximum 27 characters long.'
          t.string  :name_it,               :limit => 27, :comment => 'The name (city) in italian that belongs to this zip code. At a maximum 27 characters long.'
          t.string  :name_rt,               :limit => 27, :comment => 'The name (city) in rheto-romanic that belongs to this zip code. At a maximum 27 characters long.'
          t.integer :language,              :limit => 2,  :comment => 'The main language in the area of this zip code. 1 = de, 2 = fr, 3 = it, 4 = rt.'
          t.integer :language_alternative,  :limit => 2,  :comment => 'The second most used language in the area of this zip code. 1 = de, 2 = fr, 3 = it, 4 = rt.'
          t.boolean :sortfile_member,                     :comment => 'Whether this ZipCode instance is included in the MAT[CH]sort sortfile.'
          t.integer :delivery_by_id,        :limit => 6,  :comment => '[CURRENTLY NOT USED] By which postal office delivery of letters is usually taken care of.'
          t.integer :community_id,          :limit => 6,  :comment => 'The community this zip code belongs to.'
          t.boolean :active,                              :comment => 'Whether this record is currently active.'
#           t.date    :valid_from,                          :comment => 'The date from which on this zip code starts to be in use.'
#           t.date    :valid_until,                         :comment => '[CURRENTLY NOT USED] The date until which this zip code is in use.'

          t.timestamps
        end

        add_index :swissmatch_zip_codes, [:code]

        # not every db supports foreign key constraints, and maybe there are also syntax differences,
        # hence wrap it
        begin
          execute <<-SQL
            ALTER TABLE swissmatch_communities
              ADD CONSTRAINT fk_sm_com_0001 FOREIGN KEY (canton_id) REFERENCES swissmatch_cantons(id)
              ADD CONSTRAINT fk_sm_com_0002 FOREIGN KEY (agglomeration_id) REFERENCES swissmatch_communities(id)
          SQL
          execute <<-SQL
            ALTER TABLE swissmatch_zip_codes
              ADD CONSTRAINT fk_sm_zip_0001 FOREIGN KEY (canton_id) REFERENCES swissmatch_cantons(id)
              ADD CONSTRAINT fk_sm_zip_0002 FOREIGN KEY (community_id) REFERENCES swissmatch_communities(id)
              ADD CONSTRAINT fk_sm_zip_0003 FOREIGN KEY (delivery_by_id) REFERENCES swissmatch_zip_codes(id)
          SQL
        rescue => e
          warn "No foreign key support (#{e})"
        end
      end
    end

    class ZipCode < ::ActiveRecord::Base
      self.table_name         = "swissmatch_zip_codes"
      self.inheritance_column = "no_sti_in_this_model" # set it to something unused, so 'type' can be used as column name

      alias_attribute :ordering_number, :id

      belongs_to :canton,      :class_name => 'SwissMatch::ActiveRecord::Canton'
      belongs_to :community,   :class_name => 'SwissMatch::ActiveRecord::Community'
      belongs_to :delivery_by, :class_name => 'SwissMatch::ActiveRecord::ZipCode'
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
