README
======


Summary
-------
Deal with swiss zip codes, cantons and communities, using the official swiss post mat[ch]
database.



Installation
------------
`gem install swissmatch`



Usage
-----
Example usage:
    require 'swissmatch/autoload' # use this to automatically load the data
    SwissMatch.zip_code(8000).first.name        # => "Zürich"
    SwissMatch.zip_code(8000, 0).name           # => "Zürich"
    SwissMatch.zip_code(8000, "Zürich").add_on  # => 0



Description
-----------
Deal with swiss zip codes.
