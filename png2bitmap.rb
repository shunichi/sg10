require 'chunky_png'

png = ChunkyPNG::Image.from_file(ARGV[0])
# puts "(w,h)=(#{png.width},#{png.height})"
w = png.width
h = png.height

(0...h).each do |y|
  line = ""
  (0...w).each do |x|
    if png[x,y] == 0x0000_00ff
      line << '#'
    else
      line << '.'
    end
  end
  puts line
end
