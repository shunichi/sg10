# sg10.rb 解説

## Quine基本形
次のrubyプログラムは自分自身と同じ文字列を出力する

```
eval $s = %q{s = %{eval $s = %q{#{$s}}}; puts(s)}
            |-----------------------------------|
             ↑    |-------------------|
eval されるプログラム   ↑                 
                     eval されたプログラムの中で元のプログラム文字列を作る部分
```

ruby をよく知らない人のためのメモ

* `eval` 文字列をrubyプログラムとして実行するメソッド
* `puts` 文字列を標準出力に出力するメソッド
* `%q{...}` シングルクォート文字列リテラル(式展開なし)の別記法
* `%{...}` ダブルクォート文字列リテラル(式展開あり)の別記法

```ruby
a = 'World'
s = %{Hello, #{a}!}
puts s # Hello, World!
```

## AA(ASCII ART)を出力する
さっきの Quine を少し変更する

```
eval$s=%w{s=%{eval$s=%w{#{$s}}*""};puts(s)}*""
```

* スペースを除去した
* `%q{...}` を `%w{...}*""` に変更した

ruby をよく知らない人のためのメモ

* `%w{apple orange lemon}` は `["apple", "orange", "lemon"]` と同じ
* `array * sep` は `array.join(sep)` と同じ

`%w` と `array * ""` を使うとプログラム文字列の中に混ぜておいたスペースや改行を除去できる。

`eval %w{p ut s "Hel llo, Wor ld!"}*""`

スペースや改行でプログラム文字列を整形して、AAを作れる。

### 超絶技巧本のサンプル
四角いプログラム

https://github.com/mame/trance-book/blob/master/4-1/square-quine.rb

スペースや改行を足し引きしても同じプログラムになるので、普通ぽく書いたスクリプトを実行してAA quine を生成する。

https://github.com/mame/trance-book/blob/master/4-1/square-quine.gen.rb


ただし、スペースや改行が除去されても動くように書いておく必要がある。

例えば

* 改行でなく `;` で文を区切る
* スペースを文字列として使いたかったら `32.chr` と書く
* `puts s` ではなく `puts(s)` と書く

### AAデータでコードを自動成形
四角のAAならプログラムで生成しやすいが、絵を書きたい場合はAAデータを別途用意する。
sg10.rb でもAAデータを用意している。

https://github.com/mame/trance-book/blob/master/2-1/smile-hello.gen.rb

## sg10.rb Quine オーバービュー
Quine部分は、こんな要素でできている。

* quine基本形 `eval$s=%w{s=%{eval$s=%w{#{$s}}*""};puts(s)}*""`
* AAデータを使ったコード成形
* 圧縮データ展開
* AAの最後のパディング

読みやすくした sg10.rb 
* https://github.com/shunichi/sg10/blob/main/doc/sg10_formatted.rb
* https://github.com/shunichi/sg10/blob/main/doc/sg10_formatted2.rb

AA元データ
* https://github.com/shunichi/sg10/blob/main/aa/b0_sg10th.txt

## 圧縮
* AAをビットマップデータとして表現する
* 標準ライブラリのzlibで圧縮
* AAに埋め込むためにASCII化する

```
# ビットマップデータ
０００１１０００ => 0x18
００１００１００ => 0x24
００１００１００ => 0x24
００１００１００ => 0x24
０１１１１１１０ => 0x7e
０１００００１０ => 0x42
０１００００１０ => 0x42
１００００００１ => 0x81
```
 
展開はこの逆
* ASCIIからzlib圧縮バイナリに変換
* zlib展開
* ビットマップデータを読んでAA生成

## ASCII化
BASE64みたいなことをしたい
https://en.wikipedia.org/wiki/Base64

プログラムに埋め込めるASCII文字は64種類より多いので、より多くの文字を使えばもっと短くできる。

ASCIIの `!`(33) 〜 `z`(122) のうち `\`(92) 以外の89文字を使いたい。
https://en.wikipedia.org/wiki/ASCII#Printable_characters

以下が、使わない文字。

* 空白文字  (quineでAAを書くときに空白文字を挿入するので使えない)
* \ (92) (rubyの文字列リテラルでエスケープになるので使いづらい)
* { (123) (rubyの文字列/配列リテラルの表現で使いたい)
* | (124) (デコード処理をシンプルにするために除外)
* } (125) (rubyの文字列/配列リテラルの表現で使いたい)
* ~ (126) (デコード処理をシンプルにするために除外)

BASE64は、任意のバイナリを6bitごとに区切ってASCII文字に対応させている。  
64は2のべき乗(2^6)なのでビット区切りによる変換ができるが、89は2のべき乗ではない。

任意のバイト列をBASE89エンコードは簡単にはできないが、整数をBASE89エンコードすることはできる。

### 整数をBASE89エンコードする例
整数を89のべき乗に分解する。

`123456 == 63*(89**0) + 49*(89**1) + 1*(89**2)`

63, 49, 1 を ASCII にマップする。  
デコードの計算をシンプルにするために 0-88 の数字を次のようにASCIIにマップする。

```
数値     => ASCIIコード
 0 - 29 => 93 - 122
30 - 88 => 33 -  91
```

これは `(c - 2) % 90 - 1` でデコードできる。

さきほどの例をASCIIに変換するとこうなる。

```
63 => 66 (B)
49 => 52 (4)
1  => 94 (^)
```

つまり、数値 123456 をBASE89エンコードすると `^4B` となる。
(デコード処理をシンプルにするために桁の大きいほうから並べる)

BASE89のASCII文字列を数値に変換する処理
```ruby
f = 0
a.unpack("C*").map{|c|f=f*89+((c-2)%90-1)};
```

### バイナリデータを１つの数値に変換
やりたいことはなんだった？

```
AAビットマップデータ -> zlib圧縮 -> ? -> 数値をBASE89エンコード -> ASCII文字列
```

? のところをどうするか？  
ruby でバイト列を数値に変換する処理ってある？  

Marshal
https://docs.ruby-lang.org/ja/latest/doc/marshal_format.html

任意のバイト列にヘッダをうまく付加すると `Marshal.load` で `Bignum` としてロードできるデータになる。  
つまり、こうなる。

```
AAビットマップデータ -> zlib圧縮 -> ヘッダをつけて Marshal.load -> 数値をBASE89エンコード -> ASCII文字列
```

展開時はこれの逆をする。

```
ASCII文字列 -> BASE89デコードして数値にする -> Marshal.dump してヘッダを除去 -> zlib展開 -> AAビットマップデータ
```

### デコード処理のコード
```ruby
# a: ASCII文字列, h:Marshalヘッダサイズ
D=->(a,h){
  f=0;
  a.unpack("C*").map{|c|f=f*89+((c-2)%90-1)};
  Zlib::Inflate.inflate(Marshal.dump(f)[h..-1]);
}
```

## 音楽再生
https://github.com/shunichi/sg10/blob/main/music.rb

### 大雑把にやってること

* 短音の波形をつくる https://ja.wikipedia.org/wiki/%E3%83%91%E3%83%AB%E3%82%B9%E7%AC%A6%E5%8F%B7%E5%A4%89%E8%AA%BF
* 譜面データを用意する
* 短音波形+譜面データの組み合わせで音楽の波形を作る 
* WAVファイルとして出力 http://soundfile.sapp.org/doc/WaveFormat/
* CLIコマンドでWAVを再生 (Linux: aplay, Mac: afplay)

超絶技巧本では `/dev/dsp` に出力するという方法で音を鳴らしているが、前提条件が厳しいし、クオリティも微妙なのでやめた。

### 曲の音声波形をつくる
* 音の高さが高いほど波が細かく（周波数が大きく、波長は小さく）なる
* 譜面データ = (音の高さのデータ,音の長さ) の配列
* 譜面データの一つ一つの音の高さと長さで短音波形を作ってつなげれば、音楽の波形データができる
* エンベロープをつけないとプチプチする https://www.g200kg.com/jp/docs/dic/envelope.html

音の波形を見るのに使えるツール
https://twistedwave.com/online

### クオリティを上げる
正弦波だと音がつまらない。  
もっと味のある音にしたいが、データサイズ/コードサイズは小さくしたい。

ファミコンサウンドなら、味があるしデータサイズも小さめで作れるかも？

ファミコンのサウンドは、３種類の音でできている。
* 矩形波（パルス波） https://youtu.be/JaItIOhrjWo
* 三角波 https://youtu.be/y4KXV_mzFSc
* ノイズ https://youtu.be/qgVoX2teRWE

(実はもう一つDMCがあるけど考えないことにする）

最初は矩形波でメロディラインだけ作ればいいかと思ってたけど、全然それっぽくならなかった。
サウンド担当と相談して、ベース（三角波）とドラム（ノイズ）つけてみようということになった。

矩形波、三角波は、計算で簡単に作れる。  
https://github.com/shunichi/sg10/blob/fbd64486b565858a3114930ef38199dee8ef40f1/music.rb#L51-L58

ノイズはちょっと面倒だけど、ファミコンのサウンドプロセッサ(APU)のエミュレーションをした。
https://wiki.nesdev.com/w/index.php/APU_Noise  
https://github.com/shunichi/sg10/blob/fbd64486b565858a3114930ef38199dee8ef40f1/music.rb#L16-L42

### 歌詞表示
rubyのスレッドを一つ作り、適当にウェイトしてputsしてるだけ。

なので、厳密には曲に同期していない。

https://github.com/shunichi/sg10/blob/fbd64486b565858a3114930ef38199dee8ef40f1/music.rb#L150

### 音楽再生プログラムをQuineに埋め込む
AAビットマップを圧縮して埋め込んだのと同じように埋め込む。  
実行時ににはデコードして eval する。