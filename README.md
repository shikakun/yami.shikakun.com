# yami.shikakun.com

:bulb: 100円払うと鹿の自宅の照明を点けたり消したりできるウェブサービスです。

[![yami.shikakun.com](https://github.com/shikakun/yami.shikakun.com/raw/master/docs/screenshot.png)](https://yami.shikakun.com/)

2016年10月16日に開催された [インターネット ヤミ市 東京 2016 〜買える力〜](http://yami-ichi.biz/tokyo/) に出店して、53人に鹿の自宅の照明を点けたり消したりできるボタンを押す権利を購入していただきましたが、照明が点滅する部屋で暮らしていたら体調が悪くなって3日でサービスを終了しました。

<img src="https://github.com/shikakun/yami.shikakun.com/raw/master/docs/yami-ichi.jpg" width="400" alt="インターネットヤミ市の様子">

（写真: [【まさに闇】インターネットヤミ市 東京 2016レポート \| ヌートン 新たな情報未発見メディア](http://nuwton.com/feature/5214/) より）

## Requirement

照明の操作には [IRKit](http://getirkit.com/) を利用しているため、IRKitと赤外線のリモコンで操作できる照明器具が必要です。

## Development

```bash
$ bundle install --path vendor/bundle --without production
$ bundle exec foreman start
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. 鹿に100円払う
6. Create a new Pull Request

## License

The MIT License (MIT)
