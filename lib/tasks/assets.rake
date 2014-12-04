namespace :assets do
  desc 'Set metadata in Redis'
  task :precompile do
    require 'sassmeister/utilities'

    include SassMeister::Utilities

    set_metadata
  end
end

