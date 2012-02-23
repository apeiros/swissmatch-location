# encoding: utf-8



require 'swissmatch/loaderror'



module SwissMatch
  class LoadError < StandardError
    attr_reader :data

    def initialize(message, data)
      super(message)
      @data = data
    end
  end
end