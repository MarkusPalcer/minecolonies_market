require 'zip'

desc "Packages the style pack as minecraft mod"
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

task package: :jar
