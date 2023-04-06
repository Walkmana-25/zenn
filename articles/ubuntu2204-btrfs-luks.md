---
title: "Ubuntu22.04をBtrfs+luks+LVM+TPMな環境にインストール"
emoji: "✨"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["ubuntu", "debian","linux","btrfs","LUKS"]
published: false
---

## はじめに

モバイルノートPCにUbuntuをインストールしている方は、次のような悩みを持っていることが多いかもしれません。

- 紛失時のデータ保護をどうするか
- LUKSを使うと起動時にパスワードを入力しなければならなくて面倒くさい
- バックアップを取ることが大変

そこで、今回はBtrfs,LUKS,lvm,tpmを組み合わせることで、上記の問題を解決していこうと思います。

## この記事のゴール

この記事では、Ubuntu 22.04 LTSを以下の環境でインストールする手順を説明します。

- ボリュームをLUKSを使用して暗号化する
- LUKSの上にはlvmを作成
- lvmの上にBtrfs論理パーティションを作ってrootにマウントする
- LUKSをTPMを使用してセキュアに自動復号化する

## 使用する技術のメリット

### LUKS

LUKS (Linux Unified Key Setup) は、Linuxで使用できる暗号化ファイルシステムです。LUKSを使用してrootパーティションを暗号化することで、コンピューターが紛失した場合でもデータを保護できます。
