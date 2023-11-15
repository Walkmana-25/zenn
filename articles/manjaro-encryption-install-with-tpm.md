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

## 目標

Manjaro Linuxを次の構成でインストールすることを目指します。

- LVM on Luks (論理ディスクを暗号化する)
- TPM2を使用して自動復号化する
- 休止状態を使用できる状態とする
- セキュリティの確保

### パーティションの構成

#### 物理ディスク

Partition | Type | Mount Point
---------|----------|---------
| /dev/sda1 | fat32 | /boot/efi |
| /dev/sda2 | ext4 | /boot |
| /dev/sda3 | lvm2 pv (Encrypted) | system |

#### 論理ディスク(/dev/sda3上のlvm2 pv)

Partition | Type | Mount Point
| /dev/system/root | btrfs | / |
| /dev/system/swap | linuxswap | none |

## 参考文献

