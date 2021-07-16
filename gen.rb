#
# bitmap -> byte array -> deflate -> Bignum -> ASCII string
#
require 'zlib'

# 制約: 横幅32pixelの倍数

def bitmap_dimension(bitmap)
  lines = bitmap.lines
  [lines[0].size - 1, lines.size]
end

def bitmap_to_bytes(bitmap)
  u8_array = []
  bitmap.each_line do |line|
    line = line.chomp
    width = line.size
    line = "%-#{width}s" % line
    # puts "|#{line}|"
    line.chars.each_slice(8) do |chars|
      u8 = chars.reduce(0) do |acc,c|
        acc <<= 1
        acc |= 1 if c != '#'
        acc
      end
      # printf "%02x\n", u8
      u8_array << u8
    end
  end
  u8_array.pack("C*")
end

def bytes_to_bitmap(bytes, width)
  bitmap = ""
  r = Regexp.compile("." * (width / 8))
  bytes.scan(r) do |slice|
    slice.each_byte do |u8|
      bit = 0x80
      8.times do
        if (u8 & bit) != 0
          bitmap << '.'
        else
          bitmap << '#'
        end
        bit >>= 1
      end
    end
    bitmap << "\n"
  end
  bitmap
end

def bytes_to_bignum(bytes)
  compressed_bytes = Zlib.deflate(bytes, Zlib::BEST_COMPRESSION)
  if compressed_bytes.size % 2 == 1
    # raise "odd length: #{compressed_bytes.size}"
    compressed_bytes += "\0\0"
  end
  # p(compressed_bytes.size / 2)
  fixnum_dump = Marshal.dump(compressed_bytes.size / 2).unpack("x3 a*")[0]
  # p fixnum_dump
  marshaled_bignum = [4, 8, "l", "+"].pack("c c a a") + fixnum_dump + compressed_bytes
  Marshal.load(marshaled_bignum)
end

def bitmap_to_bignum(bitmap)
  bytes = bitmap_to_bytes(bitmap)
  bytes_to_bignum(bytes)
end

def load_marshaled_fixnum(bytes)
  len = bytes.unpack("c")[0]
  # puts "len: #{len}"
  if len == 0
    [0, bytes[1..-1]]
  elsif 5 < len && len < 128
    [len - 5, bytes[1..-1]]
  elsif -129 < len && len < -5
    [len + 5, bytes[1..-1]]
  else
    n1, n2, n3, n4 = (bytes[1,(len.abs)] + "\0\0\0").unpack("C4")
    # p [n1, n2, n3, n4]
    case len
    when -3;           n4 = 255
    when -2;      n3 = n4 = 255
    when -1; n2 = n3 = n4 = 255
    end
    n = (0xffffff00 | n1) &
      (0xffff00ff | n2 * 0x100) &
      (0xff00ffff | n3 * 0x10000) &
      (0x00ffffff | n4 * 0x1000000)
    n = -((n ^ 0xffff_ffff) + 1) if len < 0
    # p n
    [n, bytes[(len.abs + 1)..-1]]
  end
end

def bignum_to_bytes(bignum)
  marshaled_bytes = Marshal.dump(bignum).unpack("x4a*")[0]
  num, compressed_bytes = load_marshaled_fixnum(marshaled_bytes)
  Zlib.inflate(compressed_bytes)
end

def bignum_to_bitmap(bignum, width)
  bytes = bignum_to_bytes(bignum)
  bytes_to_bitmap(bytes, width)
end

# 30 - 88 => 33 -  91
#  0 - 29 => 93 - 122
def bignum_to_ascii(bignum)
  b = bignum
  u8_array = []
  while b > 0
    b, r = b.divmod(89)
    u8_array << (r < 30 ? r + 93 : r + 3)
  end
  u8_array.reverse.pack("C*")
end

# (c-2)%90-1 の式で !(33) - [(91), ](93) - z(122) の文字を 0-88 の数値に変換している。
# 33 -  91 => 30 - 88
# 93 - 122 =>  0 - 29
#
# 使われない文字
# 92 \
# 123 {
# 124 |
# 125 }
def ascii_to_bignum(str)
  f = 0
  str.unpack("C*").map{|c|f=f*89+((c-2)%90-1)};
  f
end

bitmap_filenames = %w[b0_sg10th.txt b1_thanks1.txt b2_thanks2.txt b3_thanks3.txt]

bitmaps = bitmap_filenames.map do |filename|
  buf = IO.read("aa/#{filename}")
  STDERR.puts "#{filename}: #{buf.gsub(/[#\n]/,"").size}"
  buf
end


w, h = bitmap_dimension(bitmaps[0])
STDERR.puts "dimension: #{w} x #{h}"
joined_bitmap = bitmaps.join
joined_bitmap = joined_bitmap.gsub(/ /, ".")

bignum = bitmap_to_bignum(joined_bitmap)
ascii = bignum_to_ascii(bignum)

def strip_comments(str)
  str.lines.map do |line|
    line = line.chomp.gsub(/#.*$/, "")
    line.gsub!(/^\s+/,"")
    line.gsub!(/\s+$/,"")
    line
  end.reject{|l| l.empty?}.join("\n")
end

music_ascii = bignum_to_ascii bytes_to_bignum strip_comments IO.read("music.rb")

def test_music_compression(music_ascii)
  music_source = bignum_to_bytes ascii_to_bignum music_ascii
  eval music_source
end

# test_music_compression(music_ascii)
# exit

# bitmap = IO.read("2.txt")
# bignum = bitmap_to_bignum(bitmap)
# ascii = bignum_to_ascii(bignum)

# # # puts ascii

# w, h = bitmap_dimension(bitmap)
# bignum2 = ascii_to_bignum(ascii)
# bitmap2 = bignum_to_bitmap(bignum2, w)

# puts bitmap
# puts bitmap2

decoded_bignum = ascii_to_bignum(ascii)
decoded_bitmap = bignum_to_bitmap(decoded_bignum, w)

if joined_bitmap != decoded_bitmap
  raise "bitmap mismatch!"
end

def gen_simple
  eval$s=%q{puts %(eval$s=%q{#$s})}
end

def marshal_header_size(str)
  f=0;
  str.unpack("C*").map{|c|f=f*89+((c-2)%90-1)};
  buf = Marshal.dump(f)
  len = buf.unpack("x4c")[0]
  if len != 0 && -4 <= len && len <= 4
    # [major, minor, l, +/-, len] + [n] * len
    5 + len
  else
    # [major, minor, l, +/-, len]
    5
  end
end

def gen(ascii, w, h, count, music_ascii)
  # t=(t+1)%N のところは手動書き換え
  # *"" の部分が  *"  " のようにクォートにスペースや改行が入るとダメ
  # %|...| の %| の間にスペースや改行が入るとダメ
  # %|...| の中身に | が入るとダメ
  # D.(...) の . と ( の間にスペースや改行が入るとダメ だった気がするけど、そうでもない
  wb = w / 8
  bs = wb*h
  ah = marshal_header_size(ascii)
  mh = marshal_header_size(music_ascii)
  format = "%032b" * (wb/4)

  t=0;
  eval $s=("F=%q{#{ascii}};M=%q{#{music_ascii}};" + %{
  require'zlib';
  D=->(a,h){
    f=0;
    a.unpack("C*").map{|c|f=f*89+((c-2)%90-1)};
    Zlib::Inflate.inflate(Marshal.dump(f)[h..-1]);;
  };
  f=D.(F,#{ah});
  } +
  "if(ARGV.first=='music');eval(D.(M,#{mh}));exit;end;" +
  %q{S=%{t=#{(t+1)%4};eval$s=%w{#$s}*"";%|}} +
  %{+F*30;#{h}.times{|n|puts(
    (
      "#{format}".%(f[t*#{bs}+#{wb}*n,#{wb}].unpack("N#{wb/4}"))
    ).gsub(/./){$&<"1" ? (32.chr) : S.slice!(0,1)}
  )};
  print(S.slice!(0,100)+'+'+'-'*27+10.chr+S.slice!(0,100));
  puts("|"+%(,#,Sonic,Garden,10th,Anniv.).split(',').join(32.chr));
  }
  ).gsub(/\s+/, "")
end

# puts ascii.size
# puts music_ascii.size
# exit

# Sonic Garden 10th Anniv.
gen(ascii, w, h, bitmap_filenames.size, music_ascii)
# bytes = bitmap_to_bytes('### #### # #')
# p bytes
# p bytes.unpack("C*")
# p bytes.unpack("C*").map { |c| "%02x" % c }.join
