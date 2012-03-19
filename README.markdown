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
### Example usage

    require 'swissmatch/autoload' # use this to automatically load the data

    # Get all zip codes for a given code, the example returns the official name of the first
    SwissMatch.zip_codes(8000).first.name                   # => "Zürich"(de, 0)

    # Get a single zip code, uniquely identified by the 4 digit code and the 2 digit add-on
    SwissMatch.zip_code(8000, 0).name                       # => "Zürich"(de, 0)

    # Get all names of a zip code for any given language (or all languages)
    SwissMatch.zip_code(8000, 0).names(:it)                 # => ["Zurigo"(it, 3)]

    # Get the suggested name for a zip code for a given language, avoiding issues with
    # zip codes that have multiple or no name for a given language.
    SwissMatch.zip_code(8000, 0).suggested_name(:it)        # => "Zurigo"(it, 3)

    # Get a zip code by 4 digit code and name, get its add-on
    SwissMatch.zip_code(8000, "Zürich").add_on              # => 0

    # SwissMatch also provides data over the swiss cantons (Kantone)
    SwissMatch.canton("ZH").name(:it)                       # => "Zurigo"
    SwissMatch.canton("Zurigo").name                        # => "Zürich"

    # SwissMatch also provides data over swiss communities (Gemeinden)
    SwissMatch.communities("Zürich").first.community_number # => 261
    SwissMatch.community(261).name                          # => "Zürich"


### SwissMatch and Databases
If you want to load the data into your database, you can use:

    swissmatch_db create
    swissmatch_db seed

This needs active_record 3.2+ to be installed, and you should either be in a rails project, or
use the -c option to specify a database configuration file.
The models used for that can be loaded by `require 'swissmatch/active_record'`.
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



Credits
-------

* <a href="http://www.awd.ch/">AWD Switzerland</a>, for donating time to work on this gem.
