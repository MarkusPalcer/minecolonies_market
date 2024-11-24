namespace :tools do
  desc "Imports schematics from the 'import' folder, putting them into the correct folders by hut type automatically"
  task :import do
    folders = JSON.parse File.read 'src/folders.json'

    moves = {}

    Dir['import/**/*.blueprint'].each do |file|
      data = CraftBook::NBT.read_file file

      tile_entities = data.find { |x| x.name == 'tile_entities' }
      raise "#{file}: no tile_entities tag found" if tile_entities.nil?

      building = tile_entities.find do |tile_entity|
        tile_entity.find do |property|
          property.name == 'id' && property.value == 'minecolonies:colonybuilding'
        end
      end
      raise "#{file}: no hut block found (no tile entity with id == 'minecolonies:colonybuilding')" if building.nil?

      building_type = building.find { |property| property.name == 'type' }
      raise "#{file}: hut block without type (no property 'type' in tile entity)" if building_type.nil?

      folder = folders[building_type.value]
      raise "#{file}: unknown building type '#{building_type.value}'; add it to src/folders.json" if folder.nil?

      target_file = File.join 'src', folder, (File.basename file)
      if File.exist?(target_file) && !ENV['FORCE']
        raise "#{file}: already exists, use FORCE=1 to force overwriting of existing files"
      end

      mkdir_p File.dirname(target_file), verbose: false

      moves[file] = target_file
    end

    moves.each_pair do |src, tgt|
      FileUtils.mv src, tgt
    end
  end

  desc 'Prints the given input NBT file as YAML'
  task :dump do
    filename = ENV["INPUT"]

    raise "INPUT not given" if filename.nil?
    raise "#{filename} does not exist" unless File.exist? filename
    raise "#{filename} is not a file" unless File.file? filename

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
