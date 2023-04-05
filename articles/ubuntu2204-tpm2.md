---
title: "Ubuntu 22.04でTPM2.0を使ってluksを自動復号化をする"
emoji: "🐙"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["ubuntu", "tpm2"]
published: true
---

### はじめに

luks上にインストールしたubuntu22.04を、起動時にパスワードを打つ代わりにTPMを使って復号化する方法を調べてみました。

### 前提条件

- luksを使ってubuntu 22.04をインストール済みの環境

### 手順

#### パッケージのインストール

```bash
sudo apt update
sudo apt install clevis-tpm2 clevis-luks clevis-initramfs -y
```

#### luks暗号化ボリュームを特定する

次の場合では、/dev/nvme1n1p2

```bash
# lsblk
nvme1n1                                       259:0    0 465.8G  0 disk  
├─nvme1n1p1                                   259:1    0  1000M  0 part  /boot
├─nvme1n1p2                                   259:2    0 463.8G  0 part  
│ └─luks-d1bbf244-6e32-42f6-9ecb-6ebe4a960961 253:0    0 463.8G  0 crypt /run/timeshift/backup
│                                                                        /var/lib/docker/btrfs
│                                                                        /home
│                                                                        /var/snap/firefox/common/host-hunspell
│                                                                        /
└─nvme1n1p3                                   259:3    0  1000M  0 part  

```

#### clevis luks bindを使用してTPM2デバイスにバインドする

```bash
# clevis luks bind -d /dev/nvme1n1p2 tpm2 '{"hash":"sha256","key":"rsa"}'
```

#### 検証

```bash
# clevis luks list -d /dev/sda2
1: tpm2 '{"hash":"sha256","key":"rsa"}'
```

#### initramfsを更新する

```bash
# update-initramfs -u
```

### 参考文献

[12.8. TPM2.0 ポリシーを使用した LUKS で暗号化したボリュームの手動登録の設定](https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/8/html/security_hardening/configuring-manual-enrollment-of-volumes-using-tpm2_configuring-automated-unlocking-of-encrypted-volumes-using-policy-based-decryption
)
