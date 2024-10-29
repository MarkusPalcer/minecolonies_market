require 'zip'
require 'craftbook/nbt'
require 'yaml'
require 'pathname'
require 'parallel'

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

desc 'Prints the given input NBT file as YAML'
task :dump do
  filename = get_file_parameter 'input'
  data = CraftBook::NBT.read_file filename
  puts YAML.dump(data)
end

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

task default: %i[clean metadata thumbnails compile]

task all: %i[default compress]
