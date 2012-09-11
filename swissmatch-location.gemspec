# encoding: utf-8

Gem::Specification.new do |s|
  s.name                      = "swissmatch-location"
  s.version                   = "0.0.1.201208"
  s.authors                   = "Stefan Rusterholz"
  s.email                     = "stefan.rusterholz@gmail.com"
  s.homepage                  = "http://github.com/apeiros/swissmatch-location"

  s.description               = <<-DESCRIPTION.gsub(/^    /, '').chomp
    Deal with swiss cantons, communities and zip codes, as provided by the swiss postal
    service.
    Additionally handle data updates provided by the swiss postal service.
  DESCRIPTION

  s.summary                   = <<-SUMMARY.gsub(/^    /, '').chomp
    Deal with swiss zip codes, cantons and communities.
  SUMMARY

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

  s.add_dependency "rubyzip"
  s.add_dependency "autocompletion", ">= 0.0.2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1")
  s.rubygems_version          = "1.3.1"
  s.specification_version     = 3
end
