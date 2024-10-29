require 'minitest/autorun'
require 'set'

regex = /(.*?)(\d+).blueprint/

Dir["src/**/*.blueprint"].each do |hut_path| 
  describe hut_path.strip do
    it "must end with a valid level number" do 
      match = regex.match hut_path
      refute_nil match, "must end with a level number"
      assert_includes (1..5), match[2].to_i, "must have a level number in the range 1..5"
    end
  end
end

Dir["src/**/*.blueprint"].group_by { |path| regex.match(path)[1] }.each_pair do |hut_name, hut_paths| 
  describe File.basename hut_name.strip do 
    it "must not have gaps in the level numbers" do
      levels = hut_paths.map {|x| regex.match x}.reject { |x| x.nil? }.map {|x| x[2].to_i }
      
      (1..levels.max).each do |level|
        assert_includes levels, level, "must contain a blueprint for level #{level}"
      end
    end
  end
end  

Dir["src/**/*.blueprint"].group_by { |path| File.basename regex.match(path)[1] }.each_pair do |hut_name, hut_paths|
  describe hut_name.strip do 
    it "must not be in two folders at the same time" do 
      hut_dirs = hut_paths.map { |x| File.dirname x }.uniq
      assert_same hut_dirs.length, 1, "The hut is found in #{hut_dirs.length} folders but should only be in one."
    end
  end
end
