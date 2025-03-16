---
title: "Ubuntuにzramを導入する"
emoji: "📝"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["ubuntu", "zram", "linux"]
published: true
---

## zramとは？

RAM上に圧縮ブロックデバイスを作成するLinuxカーネルモジュール。
今回はSwapに利用し、圧縮メモリとして使用する。

[zram ArchWiki](https://wiki.archlinux.jp/index.php/Zram#zram_.E3.81.AE.E7.B5.B1.E8.A8.88.E3.82.92.E7.A2.BA.E8.AA.8D.E3.81.99.E3.82.8B)

## インストール方法

今回はUbuntu 22.04 LTSを使用する。

1. 必要なパッケージをインストール
   - zram kernel module: linux-image-extra-virtualパッケージ
   - systemd-zram-generator

   ```bash
   sudo apt update
   sudo apt install linux-image-extra-virtual systemd-zram-generator -y
   ```

2. 設定ファイルの編集

    ```conf:/etc/systemd/zram-generator.conf
    [zram0]
    host-memory-limit = none
    zram-fraction = 0.5
    compression-algorithm = zstd
    ```

3. 有効化

    ```bash
    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0.service
    ```

4. swappinessの調整

    zramは通常のswap fileやswap partitionよりも高速である。よって、通常よりメモリスワップの優先度を上げることで、システムのパフォーマンスの向上を図ることができる。

    次のファイルに以下の内容を追加する。

   ```conf:/etc/sysctl.conf
   vm.swappiness = 200
   ```

   再読み込みする。

   ```bash
   sysctl -p
   ```

5. 確認

   次のコマンドを使用することで確認することが出来る。

   ```bash
   zramctl
   swapon --show
   free -m
   ```

## 自動インストール

先ほどの手順をShell Scriptにする。

```bash:install-zram.sh
#!/bin/bash
set -e

# このスクリプトはroot権限で実行してください。
if [ "$EUID" -ne 0 ]; then
  echo "このスクリプトはroot権限で実行してください。"
  exit 1
fi

echo "パッケージの更新とインストールを開始します…"
apt update
apt install -y linux-image-extra-virtual systemd-zram-generator

CONF_FILE="/etc/systemd/zram-generator.conf"
echo "設定ファイル ${CONF_FILE} を作成・編集します…"

if [ -f "$CONF_FILE" ]; then
  echo "${CONF_FILE} が存在するため、既存のコメント行はそのままに、[zram0] セクションの設定を更新します…"
  # awkで[zram0]セクション内の設定行（コメント行は無視）を更新し、キーが無い場合は末尾に追記する
  awk -v section="zram0" '
BEGIN {
  in_section = 0;
  host_found = 0;
  fraction_found = 0;
  algo_found = 0;
}
/^\[.*\]$/ {
  if (in_section) {
    # セクション終了時に未設定のキーを追記
    if (host_found == 0) print "host-memory-limit = none";
    if (fraction_found == 0) print "zram-fraction = 0.5";
    if (algo_found == 0) print "compression-algorithm = zstd";
  }
  if ($0 == "[" section "]") {
    in_section = 1;
  } else {
    in_section = 0;
  }
  print;
  next;
}
{
  if (in_section && $0 !~ /^[[:space:]]*#/) {
    if ($0 ~ /^[[:space:]]*host-memory-limit[[:space:]]*=/) {
      print "host-memory-limit = none";
      host_found = 1;
      next;
    }
    if ($0 ~ /^[[:space:]]*zram-fraction[[:space:]]*=/) {
      print "zram-fraction = 0.5";
      fraction_found = 1;
      next;
    }
    if ($0 ~ /^[[:space:]]*compression-algorithm[[:space:]]*=/) {
      print "compression-algorithm = zstd";
      algo_found = 1;
      next;
    }
  }
  print;
}
END {
  if (in_section) {
    if (host_found == 0) print "host-memory-limit = none";
    if (fraction_found == 0) print "zram-fraction = 0.5";
    if (algo_found == 0) print "compression-algorithm = zstd";
  }
}
' "$CONF_FILE" > "${CONF_FILE}.tmp"
  mv "${CONF_FILE}.tmp" "$CONF_FILE"
else
  echo "${CONF_FILE} が存在しないため、新規作成します…"
  cat <<EOF > "$CONF_FILE"
[zram0]
host-memory-limit = none
zram-fraction = 0.5
compression-algorithm = zstd
EOF
fi

echo "設定ファイルの更新が完了しました。"

echo "Systemdのデーモンを再読み込みし、zramサービスを起動します…"
systemctl daemon-reload
systemctl start systemd-zram-setup@zram0.service

echo "vm.swappiness の設定を /etc/sysctl.conf に追加・更新します…"
if grep -q '^vm.swappiness' /etc/sysctl.conf; then
  sed -i 's/^vm\.swappiness.*/vm.swappiness = 200/' /etc/sysctl.conf
else
  echo 'vm.swappiness = 200' >> /etc/sysctl.conf
fi

echo "sysctl 設定の再読み込みを実行します…"
sysctl -p

echo "設定状況の確認を行います…"
echo "----- zramctl の出力 -----"
zramctl
echo "----- swapon --show の出力 -----"
swapon --show
echo "----- free -m の出力 -----"
free -m

echo "すべての処理が完了しました。"

```

## 参考文献

- [スワップされて困っちゃうのでswappinessを設定する Qiita](https://qiita.com/ikuwow/items/f0b4d1f509a0b83b5d7e)
- [スワップ領域をまだディスク領域使って作成してます？メモリを使った zram の紹介 Qiita](https://qiita.com/___nix___/items/cecb46a5f54637f6b597)
- [Has zram been removed in the latest ubuntu (17.10)? ask Ubuntu](https://askubuntu.com/questions/989263/has-zram-been-removed-in-the-latest-ubuntu-17-10)
- [zram - ArchWiki](https://wiki.archlinux.jp/index.php/Zram#zram_.E3.81.AE.E7.B5.B1.E8.A8.88.E3.82.92.E7.A2.BA.E8.AA.8D.E3.81.99.E3.82.8B)
