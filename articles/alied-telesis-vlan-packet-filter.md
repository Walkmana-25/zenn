---
title: "Alied TelesisのL3スイッチでVLANパケットフィルタを設定する"
emoji: "📝"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [network, x510, vlan, aliedtelesis]
published: false
---

## 目的

Alied TelesisのL3 Switchであるx510-28GTXを購入し、自宅で運用しているが、VLANとパケットフィルターの設定が必要だったので、その手順をまとめる。

## 前提条件

- vLanが設定されていること
- vLan InterfaceにIPアドレスが設定されていること
  - L3スイッチとして稼働するように設定されていること

## 手順

1. Hardware access list (list)を作成
2. Hardware access list (IP)を作成
3. vLan access mapの作成
4. vLanにaccess mapを適応
5. 動作確認

## 1. access-list hardware(list)の作成

ハードウェアアクセスリストはエントリーを1つしか持つことができない。
よって、access-list hardware(list)を作成し、その中に複数のエントリーを追加する。公式マニュアルにはシーケンス番号を利用した設定とある。  
[公式マニュアルの該当ページ](https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.3-0.1/001763b/docs/overview-30.html#sec5)

```shell
awplus(config)# access-list hardware listname
```


## 参考文献

https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.2a-0.1/001763a/docs/overview-30.html
https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.3-0.1/001763b/docs/access-group@116INTERFACE.html
https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.3-0.1/001763b/docs/overview-33.html
https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.7-0.1/613-001763_S/docs/vlan_access-map@100CONFIG.html
