desc "Creates files from templates"
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
