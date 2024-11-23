require 'zip'
require 'craftbook/nbt'
require 'yaml'
require 'pathname'
require 'parallel'
require 'minitest/test_task'
require 'fileutils'
require 'erubis'
require 'time'

woods = {
  'Oak' => 'oak',
  'Spruce' => 'spruce',
  'Birch' => 'birch',
  'Jungle' => 'jungle',
  'Acacia' => 'acacia',
  'Dark Oak' => 'dark_oak'
}.freeze

colors = {
  'Light Gray' => 'light_gray',
  'Gray' => 'gray',
  'Black' => 'black',
  'Brown' => 'brown',
  'Red' => 'red',
  'Orange' => 'orange',
  'Yellow' => 'yellow',
  'Lime' => 'lime',
  'Green' => 'green',
  'Cyan' => 'cyan',
  'Light Blue' => 'light_blue',
  'Blue' => 'blue',
  'Purple' => 'purple',
  'Magenta' => 'magenta',
  'Pink' => 'pink'
}.freeze

def get_parameter(name)
  name.upcase!
  value = ENV[name]
  raise "#{name} not given" if value.nil?

  value
end

def get_file_parameter(name)
  value = get_parameter name
  raise "#{value} does not exist" unless File.exist? value
  raise "#{value} is not a file" unless File.file? value

  value
end

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

def set_string_tags(data, name, value)
  case data
  when CraftBook::NBT::EnumerableTag
    data.each do |item|
      set_string_tags item, name, value
    end
  when CraftBook::NBT::StringTag
    return unless data.name == name

    data.value = value
  else
    # Ignore unknown tags
  end
end

task :clean do
  rm_rf 'out', verbose: false
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

  metadata
end

task :compile do
  generated_items = Rake::FileList['src/**/*.blueprint'].map { |f| Pathname.new(f) }.product(colors.to_a, woods.to_a)

  Parallel.each(generated_items, progress: 'Generating') do |item|
    file, (color_name, color), (wood_name, wood) = item

    out_dir = file.relative_path_from('src').dirname
    blueprint_dir = "out/pack/#{out_dir}/#{wood_name}/#{color_name}"
    mkdir_p blueprint_dir, verbose: false

    out_file = "#{blueprint_dir}/#{file.basename('.json')}"

    data = CraftBook::NBT.read_file file

    # Generate variant
    replace! data, 'oak', wood
    replace! data, 'red', color

    # Light lanterns
    set_string_tags data, 'lit', "'true'"

    # Update metadata
    set_string_tags data, 'pack', metadata['name']
    set_string_tags data, 'path', out_file

    CraftBook::NBT.write_file out_file, data, level: :optimal
  end
end

task :thumbnails do
  mkdir_p 'out/pack', verbose: false
  Dir.chdir('src') do
    sh('cp --parents ./**/*.png ../out/pack/', verbose: false)
  end
end

task zip: :compile_templates do
  out_file = "#{metadata['name']}.zip"

  Dir.chdir('out/pack') do
    sh "zip -q -r ../#{out_file} .", verbose: false
  end
end

task :compile_templates do
  puts 'Compiling templates'
  FileList['templates/**/*.erb'].each do |template|
    relative_path = Pathname.new(template).relative_path_from('templates').sub '.erb', ''
    puts "  #{relative_path}"
    eruby = Erubis::Eruby.new(File.read(template))
    mkdir_p "out/#{relative_path.dirname}", verbose: false
    File.write "out/#{relative_path}", eruby.evaluate(metadata)
  end
end

task jar: :compile_templates do
  out_file = "out/#{metadata['name']}-v#{metadata['version']}.jar"
  package_folder = "blueprints/#{metadata['name'].gsub(/[^\w\.]/, '_')}/#{metadata['displayName'].gsub(/[^\w\.]/, '_')}/"

  puts "Packing #{out_file}"

  rm out_file, verbose: false if File.exist? out_file
  Zip::File.open(out_file, create: true) do |zip_file|
    Dir['out/pack/**/*'].each do |file|
      target = file.sub('out/pack/', package_folder)
      puts "  #{file} -> #{target}"
      zip_file.add target, file
    end

    Dir['out/jar/**/*'].each do |file|
      target = file.sub('out/jar/', '')
      puts "  #{file} -> #{target}"
      zip_file.add target, file
    end
  end
end

task compress: %i[zip jar]

def get_version()
  version = ENV.fetch('VERSION', "0")
  version = version[1..] if version.start_with? 'v'
  version.to_i
end

task :check_version do
  # Ensure that the version number is given and a number
  raise 'VERSION not given or not an integer > 0' unless get_version > 0

  puts "Building version #{get_version}"
end

task default: %i[clean compile_templates thumbnails compile compress]

Minitest::TestTask.create(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.warning = false
  t.test_globs = ['test/**/*.rb']
end

namespace :tools do
  desc "Imports schematics from the 'import' folder, putting them into the correct folders by hut type automatically"
  task :import do
    folders = JSON.parse File.read 'src/folders.json'

    moves = {}

    Dir['import/**/*.blueprint'].each do |file|
      data = CraftBook::NBT.read_file file

      tile_entities = data.find { |x| x.name == 'tile_entities' }
      raise "#{file}: no tile_entites tag found" if tile_entities.nil?

      building = tile_entities.find { |tile_entity| tile_entity.find { |property| property.name == 'id' && property.value == 'minecolonies:colonybuilding' }}
      raise "#{file}: no hut block found (no tile entity with id == 'minecolonies:colonybuilding')" if building.nil?

      building_type = building.find {|property| property.name == 'type' }
      raise "#{file}: hut block without type (no property 'type' in tile entity)" if building_type.nil?

      folder = folders[building_type.value]
      raise "#{file}: unknown building type '#{building_type.value}'; add it to src/folders.json, so I know where to import to" if folder.nil?

      target_file = File.join 'src', folder, (File.basename file)
      raise "#{file}: already exists, use FORCE=1 to force overwriting of existing files" if File.exist?(target_file) && !ENV['FORCE']

      mkdir_p File.dirname(target_file), verbose: false

      moves[file] = target_file
    end

    moves.each_pair do |src, tgt|
      FileUtils.mv src, tgt
    end
  end

  desc 'Prints the given input NBT file as YAML'
  task :dump do
    filename = get_file_parameter 'input'
    data = CraftBook::NBT.read_file filename
    puts YAML.dump(data)
  end

  desc 'Replaces strings within a schematic file'
  task :replace do
    raise 'no search string given with SEARCH' unless ENV['SEARCH']
    raise 'no replacement given with REPLACE' unless ENV['REPLACE']
    raise 'no input file given with INPUT' unless ENV['INPUT']
    raise 'no output file given with OUTPUT' unless ENV['OUTPUT']

    data = CraftBook::NBT.read_file ENV['INPUT']

    replace! data, ENV['SEARCH'], ENV['REPLACE']

    CraftBook::NBT.write_file ENV['OUTPUT'], data, level: :optimal
  end
end
