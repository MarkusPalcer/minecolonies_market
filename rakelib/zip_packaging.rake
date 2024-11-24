desc "Packages the style-pack as zipfile"
task :zip do
  out_file = "#{metadata['name']}.zip"

  Dir.chdir('out/pack') do
    sh "zip -q -r ../#{out_file} .", verbose: false
  end
end

task package: :zip
