return if defined?(SimpleCov) && SimpleCov.running

require 'simplecov'

SimpleCov.start 'rails' do
  enable_coverage :branch

  # Only track files in app/ directory
  track_files 'app/**/*.rb'

  # Explicitly filter out non-app code
  add_filter '/spec/'
  add_filter '/test/'
  add_filter '/features/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
  add_filter '/lib/'
  add_filter do |source_file|
    !source_file.filename.include?('/app/')
  end

  # Filter out ActionCable channels (tested via RSpec, hard to test in Cucumber)
  add_filter '/app/channels/'

  # Add groups for better reporting
  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Channels', 'app/channels'
  add_group 'Jobs', 'app/jobs'
  add_group 'Helpers', 'app/helpers'
  add_group 'Services', 'app/services'

  minimum = ENV['SIMPLECOV_MINIMUM_COVERAGE']
  minimum_coverage minimum.to_i if minimum
end
