# encoding: utf-8

# Require this file to automatically load swissmatch location data
# It will try to load from a try the directory in SWISSMATCH_DATA
# If the env variable SWISSMATCH_DATA is not set, it'll try the data dir in the gem.

require 'swissmatch/location'
SwissMatch.load
