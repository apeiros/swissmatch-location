# encoding: utf-8

begin
  require 'rubygems/version' # newer rubygems use this
rescue LoadError
  require 'gem/version' # older rubygems use this
end

module SwissMatch
  module Location

    # The version of this package.
    Version = Gem::Version.new("0.0.1")
  end
end
