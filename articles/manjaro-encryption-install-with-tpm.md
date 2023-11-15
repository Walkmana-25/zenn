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
    mkfsbtrfs /dev/mapper/system-root
    ```

### OSのインストール

1. Manjaro Linuxインストーラーを起動します。
1. `ストレージデバイスを選択`までセットアップを続けます。
1. `手動パーティション`を選択します。
1. 次の画像のようにマウントポイントを指定します。
    物理ディスク
    /dev/vda1 : /boot/efi
    /dev/vda2 : /boot
    論理ディスク
    /dev/mapper/system-root: /

:::message
インストールが完了しても再起動しないでください。
:::

### インストール後の設定

1. ファイルシステムをマウントします。

    ```bash
    mount -o subvol=@ /dev/mapper/system-root /mnt
    mount -o subvol=@home /dev/mapper/system-root /mnt/home
    mount -o subvol=@cache /dev/mapper/system-root /mnt/var/cache
    mount -o subvol=@log /dev/mapper/system-root /mnt/var/log
    mount /dev/vda2 /mnt/boot
    mount /dev/vda1 /mnt/boot/efi
    ```

1. chrootに入る

    ```bash
    #arch linuxの場合は、`arch-chroot`を使用
    manjaro-chroot /mnt
    ```

1. mkinitcpioの設定

    keyboard,encrypt,lvm2 フックをfilesystemの前に追加します。

    ``` text
    #/etc/mkinitcpio.conf
    HOOKS=(... keyboard keymap block encrypt lvm2 ... filesystems ...)
    ```

1. mkinitcpioの生成

    ```bash
    mkinitcpio -p linux65
    ```

1. ブートローダーの設定

    `/etc/default/grub`の`GRUB_CMDLINE_LINUX_DEFAULT`に次の内容を追記してください。UUIDは/dev/sdXXのUUIDに置き換えてください。

    ```bash
    #UUIDの確認方法
    ls -al /dev/disk/by-uuid
    ```

    ```text
    cryptdevice=UUID=device-UUID:cryptolvm root=/dev/mapper/system-root
    ```

1. 設定の適応

    ```bash
    update-grub
    ```

1. chrootを抜け、インストールディスクを抜き、再起動します。起動時にパスワードを入力してください。

### 休止状態の設定

1. swap paritionの作成

    ```bash
    mkswap /dev/mapper/system-swap
    ```

1. fstabの設定

    次の内容を`/etc/fstab`に追記します。

    ```text
    /dev/mapper/system-swap none swap defaults 0 0
    ```

1. mkinitcpioの設定
    `/etc/mkinitcpio.conf`を開き、`HOOKS`の`filesystems`の前に`resume`を追加します。

1. ブートローダーの設定
    `/etc/default/grub`の`GRUB_CMDLINE_LINUX_DEFAULT`の`root=`の前に次の内容を追記してください。

    ```text
    resume=/dev/mapper/system-swap
    ```

1. 設定を適応します

    ```bash
    mkinitcpio -p linux65
    update-grub
    ```

1. 一度再起動します

1. テスト

    ここで休止状態が機能するかテストしてください。

### セキュアブートの設定

## 参考文献

[dm-crypt/システム全体の暗号化](https://wiki.archlinux.jp/index.php/Dm-crypt/%E3%82%B7%E3%82%B9%E3%83%86%E3%83%A0%E5%85%A8%E4%BD%93%E3%81%AE%E6%9A%97%E5%8F%B7%E5%8C%96#LVM_on_LUKS)
[【Linux】ボリュームのUUIDを確認する方法](https://zenn.dev/supersatton/articles/bb82cfcf0a2b1f)
https://wiki.archlinux.jp/index.php/%E9%9B%BB%E6%BA%90%E7%AE%A1%E7%90%86/%E3%82%B5%E3%82%B9%E3%83%9A%E3%83%B3%E3%83%89%E3%81%A8%E3%83%8F%E3%82%A4%E3%83%90%E3%83%8D%E3%83%BC%E3%83%88#.E3.83.8F.E3.82.A4.E3.83.90.E3.83.8D.E3.83.BC.E3.82.B7.E3.83.A7.E3.83.B3