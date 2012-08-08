# encoding: utf-8



require 'swissmatch/loaderror'



module SwissMatch

  # Used to indicate an error while loading the swissmatch data.
  class LoadError < StandardError

    # Data associated with the error
    attr_reader :data

    # @param [String] message
    #   Same as Exception#initialize, the message of the exception
    # @param [Object] data
    #   Arbitrary data
    def initialize(message, data)
      super(message)
      @data = data
    end
  end
end