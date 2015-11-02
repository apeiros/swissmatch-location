# encoding: utf-8

Gem::Specification.new do |s|
  s.name                      = "swissmatch-location"
  s.version                   = "1.0.1"
  s.authors                   = "Stefan Rusterholz"
  s.email                     = "stefan.rusterholz@gmail.com"
  s.homepage                  = "http://github.com/apeiros/swissmatch-location"
  s.license                   = "BSD 2-Clause License"

  s.description               = <<-DESCRIPTION.gsub(/^    /, '').chomp
    Deal with swiss zip codes, communities, districts and cantons, using the official swiss post mat[ch] database.
    Additionally handle data updates provided by the swiss postal service.
  DESCRIPTION

  s.summary                   = <<-SUMMARY.gsub(/^    /, '').chomp
    Deal with swiss zip codes, communities, districts and cantons, using the official swiss post mat[ch] database.
  SUMMARY

  s.post_install_message      = <<-END_OF_MESSAGE.gsub(/^    /, '').chomp
    \e[1;37;41m IMPORTANT!                                                                     \e[0m
    Due to a change in the license agreement of the swiss post, I'm no longer
    allowed to ship the data together with the gem. Please read the README for
    instructions to install and update the data.
    You can find the readme here: https://github.com/apeiros/swissmatch-location

  END_OF_MESSAGE

  s.files                     =
    Dir['bin/**/*'] +
    Dir['data/**/*'] +
    Dir['lib/**/*'] +
    Dir['rake/**/*'] +
    Dir['test/**/*'] +
    Dir['*.gemspec'] +
    %w[
      LICENSE.txt
      Rakefile
      README.markdown
    ]

  if File.directory?('bin') then
    executables = Dir.chdir('bin') { Dir.glob('**/*').select { |f| File.executable?(f) } }
    s.executables = executables unless executables.empty?
  end

  s.add_dependency "unicode"
  s.add_dependency "autocompletion", ">= 0.0.3"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1")
  s.rubygems_version          = "1.3.1"
  s.specification_version     = 3
end
