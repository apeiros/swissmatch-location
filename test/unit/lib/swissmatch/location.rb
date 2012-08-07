# encoding: utf-8

require 'swissmatch/location'

suite "SwissMatch::Location" do

  test "SwissMatch::canton" do
    assert_kind_of SwissMatch::Canton, SwissMatch.canton('ZH')
  end
end
