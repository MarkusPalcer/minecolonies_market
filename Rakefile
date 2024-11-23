require 'zip'
require 'craftbook/nbt'
require 'yaml'
require 'pathname'
require 'parallel'
require 'minitest/test_task'
require 'fileutils'

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

blueprints = Rake::FileList['src/**/*.blueprint']



task :metadata do
  pack_metadata = JSON.parse File.read('src/pack.json')

  blueprints.each do |file|
    data = CraftBook::NBT.read_file file
    data.each do |tag|
      next if tag.name != 'required_mods'

      tag.each do |entry|
        pack_metadata['mods'] << entry.value
      end
    end
  end

  pack_metadata['mods'].uniq!

  mkdir_p 'out/pack', verbose: false
  File.write('out/pack/pack.json', JSON.dump(pack_metadata))
end

task compile: [:metadata] do
  generated_items = blueprints.map { |f| Pathname.new(f) }.product(colors.to_a, woods.to_a)
  metadata = JSON.parse File.read 'out/pack/pack.json'

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

task :compress do
  metadata = JSON.parse File.read 'out/pack/pack.json'
  out_file = "#{metadata['name']}.zip"

  Dir.chdir('out/pack') do
    sh "zip -q -r ../#{out_file} .", verbose: false
  end
end

def get_version() 
  version = ENV["VERSION"]
  raise "VERSION not given" unless version
  version = version[1..-1] if version.start_with? "v"
  version = version.to_i
  raise "VERSION needs to be an integer > 0" unless version > 0
  version
end

task :prepare_release do 
  # Ensure that the version number is given and a number
  puts "Building version #{get_version}"
end

task :patch_version do 
  pack_metadata = JSON.parse File.read 'out/pack/pack.json'
  pack_metadata["version"] = get_version
  File.write('out/pack/pack.json', JSON.dump(pack_metadata))
end

task default: %i[clean metadata thumbnails compile]

task release: %i[prepare_release default patch_version compress]

task all: %i[default compress]

Minitest::TestTask.create(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = false
  t.test_globs = ["test/**/*.rb"]
end

namespace :tools do
  desc "Imports schematics from the 'import' folder, putting them into the correct folders by hut type automatically"
  task :import do 
    folders = JSON.parse File.read 'src/folders.json'
  
    moves = {}
  
    Dir["import/**/*.blueprint"].each do |file|
      data = CraftBook::NBT.read_file file
  
      tile_entities = data.find { |x| x.name == "tile_entities" }
      raise "#{file}: no tile_entites tag found" if tile_entities.nil?
  
      building = tile_entities.find { |tile_entity| tile_entity.find { |property| property.name == "id" && property.value == "minecolonies:colonybuilding" }}
      raise "#{file}: no hut block found (no tile entity with id == 'minecolonies:colonybuilding')" if building.nil?
  
      building_type = building.find {|property| property.name == "type" }
      raise "#{file}: hut block without type (no property 'type' in tile entity)" if building_type.nil?
  
      folder = folders[building_type.value]
      raise "#{file}: unknown building type '#{building_type.value}'; add it to src/folders.json, so I know where to import to" if folder.nil?
  
      target_file = File.join "src", folder, (File.basename file)
      raise "#{file}: already exists, use FORCE=1 to force overwriting of existing files" if File.exist?(target_file) && !ENV["FORCE"]
  
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

  desc "Replaces strings within a schematic file"
  task :replace do 
    raise "no search string given with SEARCH" unless ENV["SEARCH"]
    raise "no replacement given with REPLACE" unless ENV["REPLACE"]
    raise "no input file given with INPUT" unless ENV["INPUT"]
    raise "no output file given with OUTPUT" unless ENV["OUTPUT"]

    data = CraftBook::NBT.read_file ENV["INPUT"]

    replace! data, ENV["SEARCH"], ENV["REPLACE"]

    CraftBook::NBT.write_file ENV["OUTPUT"], data, level: :optimal
  end
end
