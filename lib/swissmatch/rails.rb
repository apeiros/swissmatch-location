# To use SwissMatch in rails, best use this line in your Gemfile:
#     gem 'swissmatch', :require => 'swissmatch/rails'



raise "This file should be required after rails has been loaded" unless defined?(ActiveSupport)

ActiveSupport.on_load(:before_initialize) do
  require 'swissmatch'

  # Load environment specific configuration
  config_path       = Rails.root.join('config/swissmatch.yml')
  configuration_all = File.exist?(config_path) ? YAML.load_file(config_path) : {}
  configuration     = configuration_all['global'] || {}
  configuration.merge!(configuration_all[Rails.env] || {})

  # Load zip-code data
  if configuration['data_directory'] then
    SwissMatch.load(SwissMatch::DataFiles.new(configuration['data_directory']))
  else
    SwissMatch.load
  end

  # Load directory services
  if configuration['telsearch_key'] then
    require 'swissmatch/telsearch'
    SwissMatch.directory_service = SwissMatch::TelSearch.new(configuration['telsearch_key'])
  end
end
