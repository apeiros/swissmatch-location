# As it seems, some zip files delivered by the post are corrupt as per rubyzips standard.
# This file contains a patch to handle the corruption.
# As it seems, the zipfiles don't report the "\n" in the zipfile-comment

begin
  require 'zip/zip'
rescue LoadError
  raise "To update the swissmatch datafiles, the rubyzip gem is required, `gem install rubyzip` or add it to your Gemfile."
end

# @private
# Patching the rubyzip gem
module Zip

  # @private
  # Patching the rubyzip gem
  class ZipCentralDirectory

    # @private
    # Patching the rubyzip gem
    def read_e_o_c_d(io) #:nodoc:
      buf = get_e_o_c_d(io)
      @numberOfThisDisk                     = ZipEntry::read_zip_short(buf)
      @numberOfDiskWithStartOfCDir          = ZipEntry::read_zip_short(buf)
      @totalNumberOfEntriesInCDirOnThisDisk = ZipEntry::read_zip_short(buf)
      @size                                 = ZipEntry::read_zip_short(buf)
      @sizeInBytes                          = ZipEntry::read_zip_long(buf)
      @cdirOffset                           = ZipEntry::read_zip_long(buf)
      commentLength                         = ZipEntry::read_zip_short(buf)
      @comment                              = buf.read(commentLength)

      # ORIGINAL
      # raise ZipError, "Zip consistency problem while reading eocd structure" unless buf.size == 0

      # PATCH, doing it in a similar fashion as Archive::Zip in perl does
      raise ZipError, "Zip consistency problem while reading eocd structure" if @comment.bytesize != commentLength
      # /PATCH
    end
  end
end
