# encoding: utf-8

require 'swissmatch/location'

suite "SwissMatch::ZipCodes" do

  test "SwissMatch::ZipCodes\#[]" do
    zip_codes = SwissMatch.zip_codes
    assert_kind_of SwissMatch::ZipCode,  zip_codes[805200]
    assert_kind_of SwissMatch::ZipCode,  zip_codes["805200"]
    assert_kind_of SwissMatch::ZipCode,  zip_codes[8052, 0]
    assert_kind_of SwissMatch::ZipCode,  zip_codes["8052", 0]
    assert_kind_of SwissMatch::ZipCode,  zip_codes[8052, "0"]
    assert_kind_of SwissMatch::ZipCode,  zip_codes["8052", 0]
    assert_kind_of SwissMatch::ZipCode,  zip_codes[8052, "Zürich"]
    assert_kind_of SwissMatch::ZipCode,  zip_codes["8052", "Zürich"]
    assert_kind_of SwissMatch::ZipCodes, zip_codes[8052]
    assert_kind_of SwissMatch::ZipCodes, zip_codes["8052"]
    assert_kind_of SwissMatch::ZipCodes, zip_codes["Zürich"]
  end
end
