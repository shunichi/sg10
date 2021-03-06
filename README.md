# SonicGarden １０周年お祝いプログラム

- ASCII アート風のプログラムになっています
- `ruby sg10.rb` とすると、別の ASCII アート風プログラムを出力します
- `ruby sg10.rb | ruby` と、出力されたプログラムをさらに実行すると、また別の ASCII アート風プログラムを出力します
- ４回実行すると最初のプログラムに戻ります(Quine です) `ruby sg10.rb | ruby | ruby | ruby`

### ボーナストラック

`ruby sg10.rb music` と実行してみてください。(Mac,Linux のみ)

大きめの音がなります。ご注意ください。

## ファイル

| ファイル名    | 内容                                             |
| ------------- | ------------------------------------------------ |
| sg10.rb       | お祝いプログラム本体                             |
| gen.rb        | sg10.rb を生成するプログラム                     |
| music.rb      | 音楽再生プログラム                               |
| png2bitmap.rb | PNG から AA ビットマップテキストを作るプログラム |
| mml2data.rb   | MML から埋め込み用音楽データを作るプログラム     |
| aa/           | AA ビットマップテキスト                          |
| music/        | 音楽データ                                       |
| doc/          | [解説](/doc/GUIDE.md)                            |

## 参考文献

- [あなたの知らない超絶技巧プログラミングの世界](https://gihyo.jp/book/2015/978-4-7741-7643-7)

## 著作権情報

- プログラム: Shunichi Ikegami
- 作詞/作曲: Takenori Oshima
- 編曲: Ryuji Nishida

プログラムの quine 部分のロジックは[あなたの知らない超絶技巧プログラミングの世界](https://gihyo.jp/book/2015/978-4-7741-7643-7)に掲載されている [山手 quine](https://github.com/mame/trance-book/blob/master/1-1-2/yamanote-quine.rb) から拝借しています。
