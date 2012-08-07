# encoding: utf-8



require 'swissmatch/loaderror'



module SwissMatch

  # Used to indicate an error while loading the swissmatch data.
  class LoadError < StandardError

    # Data associated with the error
    attr_reader :data

    def initialize(message, data)
      super(message)
      @data = data
    end
  end
end