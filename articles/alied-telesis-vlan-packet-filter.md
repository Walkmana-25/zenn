---
title: "Alied TelesisのL3スイッチでVLANパケットフィルタを設定する"
emoji: "📝"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: [network, x510, vlan, aliedtelesis]
published: true
---

## 目的

Alied TelesisのL3 Switchであるx510-28GTXを購入し、自宅で運用しているが、VLANとパケットフィルターの設定が必要だったので、その手順をまとめる。

## 前提条件

- VLANが設定されていること
- VLAN InterfaceにIPアドレスが設定されていること
  - L3スイッチとして稼働するように設定されていること

## 手順

1. Hardware access list (list)を作成
2. Hardware access list (seq entry)を作成
3. VLAN access mapの作成
4. VLANにaccess mapを適応
5. 動作確認

## 1. access-list hardware(list)の作成

ハードウェアアクセスリストはエントリーを1つしか持つことができない。そのため、暗黙のdenyは存在しない。
よって、access-list hardware(list)を作成し、その中に複数のエントリーを追加する。  
公式マニュアルにはシーケンス番号を利用した設定とある。  
[公式マニュアルの該当ページ](https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.3-0.1/001763b/docs/overview-30.html#sec5)

```shell
awplus(config)# access-list hardware listname
```

## 2. access-list hardware(seq entry)の作成

```shell
# 192.168.100.0/24に所属するホストから192.16.0.0/24へのIPパケットを破棄
awplus(config-ip-hw-acl)# deny ip 192.168.100.0/24 192.16.0.0/24
```

詳細なコマンドについては[公式リファレンス](https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.2a-0.1/001763a/docs/access-list_hardware(seq_entry)@912HWACL.html)を参照してください。

:::message
フィルターは上から順（シーケンス番号が低い順）に評価される。
:::

## 3. VLAN access mapの作成

VLANアクセスマップを使用して、フィルタリングに使用するハードウェアアクセスリストを指定する。

```shell
# deny-ruleという名前のアクセスマップを作成し、アクセスリストlistnameを適応
awplus(config)# vlan access-map deny-rule
awplus(config-vlan-access-map)# match access-group listname
```

:::message
複数アクセスリストを適応した場合、追加した順で評価される。
:::

## 4. VLANにaccess mapを適応

```shell
#vlan48にVLANアクセスマップdeny-ruleを適応する
awplus(config)# vlan filter deny-rule vlan-list 48 input
```

## 5. 動作確認

```shell
#VLANアクセスマップの情報を表示
awplus# show vlan access-map
#VLANインターフェースに適応したVLANアクセスマップdeny-ruleの情報を表示する
awplus# show vlan filter deny-rule
```

適宜、pingコマンドを使用してパケットフィルターが正常に動作しているか確認する。


## 参考文献

https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.2a-0.1/001763a/docs/overview-30.html
https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.3-0.1/001763b/docs/access-group@116INTERFACE.html
https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.3-0.1/001763b/docs/overview-33.html
https://www.allied-telesis.co.jp/support/list/switch/x510/rel/5.4.7-0.1/613-001763_S/docs/vlan_access-map@100CONFIG.html
https://www.allied-telesis.co.jp/support/list/awp/rel/5.5.0-1.1/613-001763_AJ/docs/vlan_filter@100CONFIG.html
https://www.allied-telesis.co.jp/support/list/awp/rel/5.5.0-1.1/613-001763_AJ/docs/show_vlan_access-map@020ENABLEEXEC.html
https://www.allied-telesis.co.jp/support/list/awp/rel/5.5.0-1.1/613-001763_AJ/docs/show_vlan_filter@020ENABLEEXEC.html
