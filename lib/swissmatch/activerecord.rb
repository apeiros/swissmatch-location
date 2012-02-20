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

    def self.seed(data_source=SwissMatch.data)
      canton2id     = {}
      community2id  = {}
      zipcode2id    = {}

      data_source.cantons.each do |canton|
        canton2id[canton] = SwissMatch::ActiveRecord::Canton.create!(canton.to_hash).id
      end
      no_agglo, is_agglo = data_source.communities.partition { |community|
        community.agglomeration == community
      }
      no_agglo.each do |community|
        hash = community.to_hash
        hash[:canton_id] = canton2id[hash.delete(:canton)]
        hash.delete(:agglomeration)
        record = SwissMatch::ActiveRecord::Community.create!(hash)
        community2id[community] = record.id
        record.update_attributes(:agglomeration_id => record.id)
      end
      is_agglo.each do |community|
        hash = community.to_hash
        hash[:canton_id]        = canton2id[hash.delete(:canton)]
        hash[:agglomeration_id] = community2id[hash.delete(:agglomeration)]
        community2id[community] = SwissMatch::ActiveRecord::Community.create!(hash).id
      end
      data_source.zip_codes.each do |zip_code|
        hash                        = zip_code.to_hash
        hash.delete(:delivery_by)
        #hash[:record_type]          = hash.delete(:type)
        hash[:canton_id]            = canton2id[hash.delete(:canton)]
        hash[:community_id]         = community2id[hash.delete(:community)]
        hash[:language]             = LanguageToCode[hash.delete(:language)]
        hash[:language_alternative] = LanguageToCode[hash.delete(:language_alternative)]
        SwissMatch::ActiveRecord::ZipCode.create!(hash).id
      end
    end

    def self.update(data_source=SwissMatch.data)
    end

    class Migration < ::ActiveRecord::Migration
      def down
        drop_table :swissmatch_cantons
        drop_table :swissmatch_communities
        drop_table :swissmatch_zip_codes
      end

      def up
        create_table :swissmatch_cantons, :comment => 'All swiss cantons as needed by swiss posts MAT[CH], includes the non-cantons DE and IT.' do |t|
          t.string  :license_tag, :comment => 'The two letter abbreviation of the cantons name as used on license plates.'
          t.string  :name,        :comment => 'The official name of the canton.'
          t.string  :name_de,     :comment => 'The name of the canton in german.'
          t.string  :name_fr,     :comment => 'The name of the canton in french.'
          t.string  :name_it,     :comment => 'The name of the canton in italian.'
          t.string  :name_rt,     :comment => 'The name of the canton in rheto-romanic.'
          t.timestamps
        end

        create_table :swissmatch_communities, :comment => 'The swiss communities as per plz_c file from the swiss posts MAT[CH].' do |t|
          t.string  :community_number,  :comment => 'A unique, never recycled identification number. Also known as BFSNR.'
          t.string  :name,              :comment => 'The official name of the community.'
          t.string  :canton_id,         :comment => 'The canton this community belongs to.'
          t.string  :agglomeration_id,  :comment => 'The community this community is considered to be an agglomeration of. Note that a main community will reference itself.'
          t.timestamps
        end

        create_table :swissmatch_zip_codes, :comment => 'The swiss zip codes as per plz_p1 and plz_p2 files from the swiss posts MAT[CH].' do |t|
          t.integer :ordering_number,       :comment => 'The postal ordering number, also known as ONRP.'
          t.integer :type,                  :comment => 'The type of the entry. One of 10 (Domizil- und Fachadressen), 20 (Nur Domiziladressen), 30 (Nur Fach-PLZ), 40 (Firmen-PLZ) or 80 (Postinterne PLZ).'
          t.integer :code,                  :comment => 'The 4 digit numeric zip code. Note that the 4 digit code alone does not uniquely identify a zip code record.'
          t.integer :add_on,                :comment => 'The 2 digit numeric code addition, to distinguish zip codes with the same 4 digit code.'
          t.integer :canton_id,             :comment => 'The canton this zip code belongs to.'
          t.string  :name,                  :comment => 'The name (city) that belongs to this zip code. At a maximum 27 characters long.'
          t.string  :name_de,               :comment => 'The name (city) in german that belongs to this zip code. At a maximum 27 characters long.'
          t.string  :name_fr,               :comment => 'The name (city) in french that belongs to this zip code. At a maximum 27 characters long.'
          t.string  :name_it,               :comment => 'The name (city) in italian that belongs to this zip code. At a maximum 27 characters long.'
          t.string  :name_rt,               :comment => 'The name (city) in rheto-romanic that belongs to this zip code. At a maximum 27 characters long.'
          t.integer :language,              :comment => 'The main language in the area of this zip code. 1 = de, 2 = fr, 3 = it, 4 = rt.'
          t.integer :language_alternative,  :comment => 'The second most used language in the area of this zip code. 1 = de, 2 = fr, 3 = it, 4 = rt.'
          t.boolean :sortfile_member,       :comment => 'Whether this ZipCode instance is included in the MAT[CH]sort sortfile.'
          t.integer :delivery_by_id,        :comment => '[CURRENTLY NOT USED] By which postal office delivery of letters is usually taken care of.'
          t.integer :community_id,          :comment => 'The community this zip code belongs to.'
          t.date    :valid_from,            :comment => 'The date from which on this zip code starts to be in use.'
          t.date    :valid_until,           :comment => '[CURRENTLY NOT USED] The date until which this zip code is in use.'

          t.timestamps
        end

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
              ADD CONSTRAINT fk_sm_com_0001 FOREIGN KEY (canton_id) REFERENCES swissmatch_cantons(id)
              ADD CONSTRAINT fk_sm_com_0002 FOREIGN KEY (community_id) REFERENCES swissmatch_communities(id)
              ADD CONSTRAINT fk_sm_com_0002 FOREIGN KEY (delivery_by_id) REFERENCES swissmatch_zip_codes(id)
          SQL
        rescue => e
          warn "No foreign key support (#{e})"
        end
      end
    end

    class ZipCode < ::ActiveRecord::Base
      self.table_name         = "swissmatch_zip_codes"
      self.inheritance_column = "no_sti_in_this_model" # set it to something unused, so 'type' can be used as column name
    end
    class Community < ::ActiveRecord::Base
      self.table_name = "swissmatch_communities"
    end
    class Canton < ::ActiveRecord::Base
      self.table_name = "swissmatch_cantons"
    end
  end
end
