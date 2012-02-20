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

If you want to load the data into your database, you can use:

    swissmatch_db create
    swissmatch_db seed

This needs active_record 3.2+ to be installed, and you should either be in a rails project, or
use the -c option to specify a database configuration file.
The models used for that can be loaded by `require 'swissmatch/active\_record'`.
See SwissMatch::ActiveRecord::Canton, SwissMatch::ActiveRecord::Community and
SwissMatch::ActiveRecord::ZipCode



Description
-----------
Deal with swiss zip codes.
