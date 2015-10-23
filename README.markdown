README
======


Summary
-------

Deal with swiss zip codes, cantons and communities, using the official swiss post mat[ch]
database.


Installation
------------

Install the gem: `gem install swissmatch-location`  
Depending on how you installed rubygems, you have to use `sudo`:
`sudo gem install swissmatch-location`  
In Ruby: `require 'swissmatch/location'`  
To automatically load the datafiles: `require 'swissmatch/location/autoload'`

**IMPORTANT!**

Due to a change in the license agreement of the swiss post, I'm no longer
allowed to ship the data together with the gem. Here's a guide on how to
install and update your swissmatch data:

1. Go to https://www.post.ch/de/pages/downloadcenter-match
2. **In the pop-up menu top-left** select "Register"
3. Once you're registered (you'll get a snail-mail letter from the post to sign),
   you visit the same page again and this time you choose "Login"
   **from the pop-up menu top-left**, the login button top right **does not work
   for this!** (the former logs you into the downloadcenter, the latter into
   the customer center).
3. After login, you choose the download page for "Address master data"
   (de: "Adressstammdaten", fr: "Base de données d'adresses de référence", it:
   "Banca dati indirizzi di riferimento")
4. Download "Existing data" (de: "Bestand", fr: "Etat", it: "Versione completa")
5. Unzip the file
6. Open a shell and cd into the directory with the unzipped master data
7. Run `swissmatch-location install-data PATH_TO_MASTER_DATA_FILE`

You can test your installation by running `swissmatch-location stats`. It should
tell you the age of the data and a number >0 of zip codes.  
A negative age is possible since the swiss post provides files which start to be
valid in the future.


Usage
-----

    require 'swissmatch/location/autoload' # use this to automatically load the data

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
    SwissMatch.community("Zürich").community_number # => 261
    SwissMatch.community(261).name                  # => "Zürich"


SwissMatch and Rails/Databases
------------------------------

If you want to load the data into your database, or use it in a rails project,
then you should look at swissmatch-rails. It provides a couple of models and
a data loading script.


Relevant Classes and Modules
----------------------------

* __{SwissMatch}__
  Convenience methods to access cantons, communities and zip codes
* __{SwissMatch::Cantons}__
  Swiss canton collection
* __{SwissMatch::Canton}__
  A swiss canton
* __{SwissMatch::Communities}__
  Swiss communities collection
* __{SwissMatch::Canton}__
  A swiss community
* __{SwissMatch::ZipCodes}__
  Swiss zip code collection
* __{SwissMatch::ZipCode}__
  A swiss zip code (a zip code can be described and uniquely identified by
  either code and city, code and add-on or the swiss posts ONRP)


Links
-----

* [Main Project](https://github.com/apeiros/swissmatch)
* [Online API Documentation](http://rdoc.info/github/apeiros/swissmatch-location/)
* [Public Repository](https://github.com/apeiros/swissmatch-location)
* [Bug Reporting](https://github.com/apeiros/swissmatch-location/issues)
* [RubyGems Site](https://rubygems.org/gems/swissmatch-location)
* [Swiss Posts MAT[CH]](http://www.post.ch/match)


License
-------

You can use this code under the {file:LICENSE.txt BSD-2-Clause License}, free of charge.
If you need a different license, please ask the author.


Credits
-------

* [Simon Hürlimann](https://github.com/huerlisi) for contributions
* [Swiss Life Select Schweiz AG](http://www.swisslife-select.ch/) for donating time to work on this gem.
