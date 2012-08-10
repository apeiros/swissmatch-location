# encoding: utf-8

require 'swissmatch/location'
require 'swissmatch/location/datafiles'

SwissMatch::Location.load(SwissMatch::Location::DataFiles.new(TEST_DATA_DIR))
