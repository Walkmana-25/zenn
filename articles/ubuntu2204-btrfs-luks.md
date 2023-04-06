---
title: "Ubuntu22.04をBtrfs+luks+LVM+TPMな環境にインストール"
emoji: "✨"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["ubuntu", "debian","linux","btrfs","LUKS"]
published: false
---

## はじめに

モバイルノートPCにUbuntuをインストールしている方は、次のような悩みを持っていることが多いのではないでしょうか。

- 紛失時のデータ保護をどうするか
- かと言ってLUKSは起動時にパスワードを入力する必要があり面倒くさい
- バックアップを取ることが大変

そこで今回はBtrfs,LUKS,lvm,tpmを組み合わせることで上記の問題を解決していこうと思います。

## この記事のゴール

Ubuntu22.04LTSを次の環境にインストールする

- ボリュームをLUKSを使用して暗号化する
- LUKSの上にはlvmを作成
- lvmの上にBtrfs論理パーティションを作ってrootにマウントする
- LUKSをTPMを使用してセキュアに自動復号化する

## 使用する技術のメリット

### LUKS

LUKS(Linux Unified Key Setup)とは、Linuxで使用することができる暗号化ファイルシステムです。LUKSでrootパーティションを暗号化することによってコンピューターの紛失時にデータを保護できます。



