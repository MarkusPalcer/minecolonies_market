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

desc "Creates all wood and color variants of the schematics"
task :compile do
  mkdir_p 'out/pack', verbose: false
  Dir.chdir('src') do
    sh('cp --parents ./**/*.png ../out/pack/', verbose: false)
  end

  generated_items = Rake::FileList['src/**/*.blueprint'].map { |f| [Pathname.new(f), CraftBook::NBT.read_file(f)] }.product(colors.to_a, woods.to_a)

  Parallel.each(generated_items, progress: 'Generating') do |item|
    (file, data), (color_name, color), (wood_name, wood) = item

    out_dir = file.relative_path_from('src').dirname
    blueprint_dir = "out/pack/#{out_dir}/#{wood_name}/#{color_name}"
    mkdir_p blueprint_dir, verbose: false

    out_file = "#{blueprint_dir}/#{file.basename('.json')}"

    data = Marshal.load(Marshal.dump(data))

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
