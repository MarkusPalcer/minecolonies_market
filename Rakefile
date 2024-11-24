require 'zip'
require 'craftbook/nbt'
require 'yaml'
require 'pathname'
require 'parallel'
require 'minitest/test_task'
require 'fileutils'
require 'erubis'
require 'time'



def replace!(data, search, replace)
  return if search == replace

  case data
  when CraftBook::NBT::EnumerableTag
    data.each { |item| replace! item, search, replace }
  when CraftBook::NBT::StringTag
    replace! data.value, search, replace
  when String
    return if data.empty?

    if data.frozen?
      puts "WARNING: Did not mutate '#{data}' because it was frozen" if data.include?(search) || data.include?(replace)
    else
      data.gsub! search, '!BLAH!'
      data.gsub! replace, search
      data.gsub! '!BLAH!', replace
    end
  else
    # Ignore unknown tags
  end
end


def gather_needed_mods()
  mods = []

  Rake::FileList['src/**/*.blueprint'].each do |file|
    data = CraftBook::NBT.read_file file
    data.each do |tag|
      next if tag.name != 'required_mods'

      tag.each do |entry|
        mods << entry.value
      end
    end
  end

  mods.uniq
end

def metadata
  return @metadata if defined? @metadata

  metadata = JSON.parse File.read('src/mod_metadata.json').sub("\uFEFF", '')

  # Calculated values
  metadata['version'] = get_version
  metadata['mods'] = gather_needed_mods
  metadata['build_time'] = Time.now.utc.iso8601

  # Fallbacks
  metadata['displayName'] = metadata['name'] unless metadata.key? 'displayName'
  metadata['name'] = metadata['displayName'] unless metadata.key? 'name'
  metadata['modLogo'] = metadata['icon'] unless metadata.key? 'modLogo'
  metadata['credits'] = '-' unless metadata.key? 'credits'

  # Fill metadata for dependencies: defaults and compiled version-range
  metadata.fetch('dependencies', {}).each_value do |dep|
    dep['mandatory'] = true unless dep.key? 'mandatory'
    dep['ordering'] = "NONE" unless dep.key? 'ordering'
    dep['side'] = "BOTH" unless dep.key? 'side'

    version_range = (dep.key?('minVersion') ? "[#{dep['minVersion']}" : '(')
    version_range << ','
    version_range << (dep.key?('maxVersion') ? "#{dep['maxVersion']}]" : ')')
    dep['versionRange'] = version_range
  end

  @metadata = metadata
end

desc "Builds and packages everything"
task default: %i[clean compile_templates compile package]
