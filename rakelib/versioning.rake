def get_version()
  version = ENV.fetch('VERSION', "0")
  version = version[1..] if version.start_with? 'v'
  version.to_i
end

desc "Checks whether the version is set correctly for a release"
task :check_version do
  # Ensure that the version number is given and a number
  raise 'VERSION not given or not an integer > 0' unless get_version > 0

  puts "Building version #{get_version}"
end
