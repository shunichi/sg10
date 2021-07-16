# 120/(tempo*len)
# 4 => 0.5 (
# 16 => 0.25

# 440.0 A
#
# [-14, -10, -9, -7, -5, -4, 0, 2, 3]
#
#      C   D   E   F   G   A   B
# O6   3,  5,  7,  8, 10, 12, 14,
# O5  -9, -7, -5, -4, -2,  0,  2,
# O4 -21,-19,-17,-16,-14,-12,-10,
# O3 -33,-31,-29,-28,-26,-24,-22,

$drum = false

DRUM_TABLE = [
  -21,-19,-17,-16,-14,-12,-10,
  -9, -7, -5, -4, -2,  0,  2,
  3
].reverse

def to_drum(s)
  DRUM_TABLE.find_index(s)
end

BASE_OCT=5 # 標準
# BASE_OCT=4

def mml2data(io);
  hs={'+'=>1,'-'=> -1}
  st=[0, 2, -9, -7, -5, -4, -2]
  data = []
  bpm=240;
  len=4;
  len_scale=16 # 音の長さがなるべく整数になるようにスケールする
  oct=5
  lno=0
  io.each_line do |line|
    lno+=1
    while line && !line.empty?
      case line;
      when /^t(\d+)/;
        # bpm=$1.to_i
      when /^l(\d+)/;
        len=$1.to_i
      when /^o(\d+)/;
        oct=$1.to_i
      when /^>/;
        oct-=1;
      when /^</;
        oct+=1;
      when /^\s+/;
      when /^r(\d*)(&r(\d*))?/
        l=$1.empty? ? len : $1.to_i
        ln=240.0/(bpm*l);
        if $2
          l=$3.empty? ? len : $3.to_i
          ln+=240.0/(bpm*l)
        end
        data+=[-99, ln*len_scale]
      when /^([a-g])([-+]?)(\d*)/
        s = (oct-BASE_OCT)*12+st[$1.ord-'a'.ord] + hs[$2].to_i
        l=$3.empty? ? len : $3.to_i
        ln=240.0/(bpm*l);
        line=$';
        while /^&([a-g])([-+]?)(\d*)/.match(line)
          s2 = (oct-BASE_OCT)*12+st[$1.ord-'a'.ord] + hs[$2].to_i
          l=$3.empty? ? len : $3.to_i
          ln+=240.0/(bpm*l);
          line=$';
        end
        s = to_drum(s) if $drum
        data+=[s,ln*len_scale]
        next
      else
        raise "error: #{lno}: #{line}"
      end;
      line=$';
    end
  end
  data.map { |v| v.to_i == v ? v.to_i : v }
end

if $0 == __FILE__
  if ARGV[0] == '-d'
    $drum = true
    ARGV.shift
  end
  s = ARGV.shift
  open(s){|i|
    puts mml2data(i).inspect.gsub(/\s+/, '')
  }
end

