2014-09 - 2015-11
-----------------

* Zip Codes removed:             42
* Zip Codes added:               37
* Short names corrected:         0
* Long names corrected:          2
* Short name language corrected: 3
* Long name language corrected:  3
* Name changed:                  9
* Names removed:                 1
* Names added:                   0

require 'set'
side="old" # "new"
other_side=
File.write("#{side}_codes.txt", SwissMatch.zip_codes.sort_by(&:ordering_number).map { |zc| "#{zc.ordering_number} #{zc.code} #{zc.add_on}" }.join("\n"))
other_onrps = File.read("#{other_side}_codes.txt").scan(/^\d+/).map(&:to_i); 0
common = (SwissMatch.zip_codes.map(&:ordering_number) & other_onrps).to_set; common.size
common_zc = SwissMatch.zip_codes.select { |zc| common.include?(zc.ordering_number) }; common_zc.size
out = common_zc.map { |zc| "#{zc.ordering_number} #{zc.code} #{zc.add_on}\n#{(zc.names+zc.names_short).map { |n| "  #{n.sequence_number} #{n.language} #{n}" }.join("\n")}" }.join("\n"); 0
File.write("#{side}_names.txt", out)
out = common_zc.map { |zc| "#{zc.ordering_number};#{zc.delivery_by && zc.delivery_by.ordering_number};#{zc.language};#{zc.language_alternative};#{zc.type};#{zc.largest_community && zc.largest_community.community_number}" }.join("\n"); 0
File.write("#{side}_attrs.txt", out)
