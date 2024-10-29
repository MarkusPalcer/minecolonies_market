require 'minitest/autorun'
require 'craftbook/nbt'
require 'set'

regex = /(.*?)(\d+).blueprint/

Dir["src/**/*.blueprint"].group_by { |path| regex.match(path)[1] }.each_pair do |hut_name, hut_paths| 
  describe hut_name.strip do
    it "should have the same dimensions in all files" do 
      sizes = hut_paths.map do |path|
        data = CraftBook::NBT.read_file path
        size_x = data.find { |x| x.name == "size_x" }.value
        size_y = data.find { |x| x.name == "size_y" }.value
        size_z = data.find { |x| x.name == "size_z" }.value

        [ size_x, size_y, size_z ]
      end
      sizes.uniq!

      assert_equal sizes.length, 1, "All blueprints need the same dimensions but I found the following dimensions: #{sizes}"
    end
  end
end

