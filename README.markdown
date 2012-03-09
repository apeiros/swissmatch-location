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
### Example usage:

    require 'swissmatch/autoload' # use this to automatically load the data
    SwissMatch.zip_codes(8000).first.name        # => "Zürich"
    SwissMatch.zip_code(8000, 0).name           # => "Zürich"
    SwissMatch.zip_code(8000, "Zürich").add_on  # => 0

### SwissMatch and Databases
If you want to load the data into your database, you can use:

    swissmatch_db create
    swissmatch_db seed

This needs active_record 3.2+ to be installed, and you should either be in a rails project, or
use the -c option to specify a database configuration file.
The models used for that can be loaded by `require 'swissmatch/active\_record'`.
See SwissMatch::ActiveRecord::Canton, SwissMatch::ActiveRecord::Community and
SwissMatch::ActiveRecord::ZipCode

### SwissMatch and Rails
To use SwissMatch in rails, best use this line in your Gemfile:

    gem 'swissmatch', :require => 'swissmatch/rails'

This will load swissmatch in rails and load the configuration from
PROJECT_ROOT/config/swissmatch.yml. The file should have the following structure:

    global:
      telsearch_key:    "your telsearch API key"
      data_directory:   "A path to where you want your data files stored, relative paths are relative to PROJECT_ROOT"
      cache_directory:  "A path to where swissmatch should store its cache"
    development:
      # same keys as for global, you can have environment specific settings here

The key 'global' will be used as the base for every environment.



Description
-----------
Deal with swiss zip codes.
