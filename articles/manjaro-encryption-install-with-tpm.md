---
title: "Manjaro LinuxでBitLockerみたいにインストールする"
emoji: "🐥"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Linux","Manjaro","TPM","Hibernete", "Arch"]
published: false
---

## はじめに

今回は、モバイルノートパソコンのセキュリティを確保するためにディスクの暗号化を行う方法を備忘録として残します。
Manjaro Linuxを使用しましたが、Arch Linux系列のOSでも使用できると思います。

## 環境

- Manjaro Linux
- TPM2搭載PC (Windows 11 対応PC)

※解説のためにQEMU/KVMを使用します。

## 目標

Manjaro Linuxを次の構成でインストールすることを目指します。

- LVM on Luks (論理ディスクを暗号化する)
- TPM2を使用して自動復号化する
- 休止状態を使用できる状態とする
- セキュアブート
- セキュリティの確保

### パーティションの構成

#### 物理ディスク

Partition | Type | Mount Point
---------|----------|---------
| /dev/vda1 | fat32 | /boot/efi |
| /dev/vda2 | ext4 | /boot |
| /dev/vda3 | lvm2 pv (Encrypted) | system |

#### 論理ボリューム(/dev/sda3上のlvm2 pv)

Partition | Type | Mount Point
---------|----------|---------
| /dev/system/root | btrfs | / |
| /dev/system/swap | linuxswap | none |

## インストール方法

:::message
コマンドはrootユーザーで実行してください。
:::

### 物理パーティションの準備

1. セキュアブートの無効化
1. Manjaro LinuxインストールディスクからBootします。
1. KDE Partition Managerなどを使用して、次のようなパーティションを作成します。

    ![partition](/images/manjaro-encryption/Screenshot_20231115_192245.png)

1. 暗号化ディスクを準備する

    ```bash
    cryptsetup luksFormat /dev/vda3
    ```

    :::message alert
    **ここで入力したパスワードは忘れないようにしてください。**
    忘れてしまうと、トラブル時にディスクを復号化できずにデータを失う恐れがあります。
    :::

1. 暗号化ディスクを開く

    ```bash
    cryptsetup open /dev/vda3 cryptolvm
    ```

    復号化されたコンテナが、`/dev/mapper/cryptolvm`から利用できます。

### 論理ボリュームの準備

1. 開いたコンテナの上にボリュームを作成

    ```bash
    pvcreate /dev/mapper/cryptolvm
    ```

1. ボリュームグループsystemを作成

    ```bash
    vgcreate system /dev/mapper/cryptolvm
    ```

1. 論理ボリュームを作成

    ```bash
    #PCのメモリより大きいサイズを指定してください。
    lvcreate -L 9G system -n swap

    lvcreate -l 100%FREE system -n root
    ```


## 参考文献

[dm-crypt/システム全体の暗号化](https://wiki.archlinux.jp/index.php/Dm-crypt/%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E5%85%A8%E4%BD%93%E3%81%AE%E6%9A%97%E5%8F%B7%E5%8C%96#LVM_on_LUKS)
