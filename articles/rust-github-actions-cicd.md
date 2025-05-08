---
title: "Rust+Github Actionsで、ReleaseまでカバーしたCICDを構築する"
emoji: "⛳"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["rust", "github", "cicd", "actions"]
published: false
---

## はじめに

質の高いコードを書くためには、効果的なCI/CDの仕組みが必要です。そして、インターネットでGitHub Actionsを利用したワークフローを調べてみると多くはdeprecatedとなったツールを使用していました。そこで、改めてワークフローを再構築したのでそのやり方を共有します。

## できること

- GitHub Actionsによる自動化
  - プルリクエスト時に複数OSでのテスト、lint、フォーマットチェックを実行
    - すべてのチェックが成功した場合のみマージを許可
- OSごとのテストとビルドの自動化
  - OSごとにテストを行うため、OS依存の問題を事前にテストできる
  - Release時に各OSに向けたバイナリを自動的に生成する
- リリース自動化
  - GitHub Releaseをトリガーに、テストとビルドを実行
  - ビルドされたバイナリを成果物として添付
- OpenSSL統合対応
  - Rustプロジェクトでの鬼門となるOpenSSLの依存関係を適切に処理
- 広範囲なLinux互換性
  - CentOS 7環境でarm64/x86_64向けにビルド
  - 低いglibcバージョン要求により、ほとんどのLinux環境で動作可能
- ビルド高速化
  - Rustのビルドキャッシュを活用して処理時間を短縮
  
## できないこと

- Rustのビルド速度の根本的な改善
  - 並列ワークフローを導入しても、本質的に時間のかかるビルドプロセスは高速化に限界がある
    - キャッシュを活用しても解消できない固有の処理時間が存在する
      - 特にWindowsのビルドがものすごく遅い
- バイナリの署名
  - 筆者が署名用の鍵を持っていないため、バイナリの署名は行っていない
  
## 前提条件

- GitHub, GitHub Actionsの知識
- Rustの基本的な知識

## ワークフローの構築

今回使うサンプルプロジェクトのディレクトリは以下の通りです。
また、このプロジェクトのGitHubリポジトリはこちらです。
[https://github.com/Walkmana-25/rust-actions-example](https://github.com/Walkmana-25/rust-actions-example)

```sh
sh-3.2$ tree -C -a -I "target" -I ".git"
.
|-- .github
|   `-- workflows
|       |-- release.yml #GitHub Releaseをトリガーにしたワークフロー
|       `-- testing.yml #Pull Request時に実行されるワークフロー
|-- .gitignore
|-- Cargo.lock
|-- Cargo.toml
|-- Cross.toml #Linuxでのクロスコンパイル用の設定ファイル
|-- LICENSE
|-- README.md
|-- doc.md
`-- src #今回使用するサンプルプロジェクトのソース
    |-- args.rs
    |-- main.rs
    |-- utils.rs
    `-- weather.rs

4 directories, 13 files
```

### サンプルプロジェクトの概要

説明のためにサンプルプロジェクトを構築しました。このプロジェクトは、Rustで開発した天気情報取得コマンドラインアプリケーションです。

#### 主な機能

- 指定された緯度・経度の天気データを取得
- 取得データの処理と表示
  - 6時間ごとの時間別天気情報
  - 今日と昨日の平均気温比較

#### 技術的特徴

- `reqwest`ライブラリによるHTTPリクエスト処理
- OpenSSL依存関係の適切な管理
  - `vendored` featureを使用してOpenSSLをソースからコンパイル
- 簡単なテストコードを実装しました

#### サンプルプロジェクトの実際の動作例

```sh
sh-3.2$ ./rust-actions-example --latitude 35.41 --longitude 139.45 #東京都千代田区の緯度経度
Fetching weather data for latitude: 35.41, longitude: 139.45...

--- Hourly Weather Data (Every 6 Hours) ---
2025-05-07 00:00: 19.9°C
2025-05-07 06:00: 21.0°C
2025-05-07 12:00: 16.1°C
2025-05-07 18:00: 13.1°C
2025-05-08 00:00: 16.8°C
2025-05-08 06:00: 19.9°C
2025-05-08 12:00: 15.1°C
2025-05-08 18:00: 13.1°C

--- Average Temperatures ---
Today's average temperature: 16.13°C
Yesterday's average temperature: 17.34°C
```

### testing.ymlの作成

まず、testing.ymlを作成します。このファイルは、Pull Request時に実行されるワークフローです。

#### testingワークフローの基本設定

```toml
name: Rust Testing

on:
  pull_request:
  push:
    branches: [ main ]
  workflow_dispatch:
  workflow_call:

env:
  CARGO_TERM_COLOR: always

jobs:
# 以下にジョブを定義
```

#### コード品質チェックの実装

最初のジョブでは、clippyとfmtの二つのリンタを走らせ、コードの静的解析を行います。

```toml
check:
  name: Rustfmt
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - name: Cache Rust dependencies
      uses: Swatinem/rust-cache@v2
    - name: Install Rust fmt
      run: rustup component add rustfmt
    - name: Install Rust clippy
      run: rustup component add clippy
    - name: Run rustfmt
      run: cargo fmt --all -- --check
    - name: Run clippy
      run: cargo clippy --all-targets --all-features -- -D warnings
```

このジョブでは、以下の処理を行っています：

- `Swatinem/rust-cache@v2`アクションを使用して依存関係をキャッシュし、ビルド時間を短縮
- rustfmtによるコードスタイルの検証
- clippyによる静的解析（D warningsオプションで警告をエラーとして扱う）

#### マルチプラットフォームテストの実装

次のジョブでは、複数のOSでのビルドとテストを実行します。

```toml
test:
  name: Test
  runs-on: ${{ matrix.os }}
  needs: ["check"]
  strategy:
    matrix:
      os: [ubuntu-latest, macos-latest, windows-latest]
  steps:
    - uses: actions/checkout@v3
    - name: Cache Rust dependencies
      uses: Swatinem/rust-cache@v2
    - name: Test Build
      run: cargo build --verbose
    - name: Run tests
      run: cargo test --verbose
```

このジョブの特徴は以下の通りです：

- `needs: ["check"]`により、コード品質チェックが成功した後にのみ実行される
- matrixを使用して、Ubuntu、macOS、Windowsの3つの環境で同時にテストを実行
  - 各プラットフォームで`cargo build`と`cargo test`を実行
- matrixの記述を変更することで、テスト対象のプラットフォームを変更できます。

### release.ymlの作成

```yaml
name: Release

permissions:
  contents: write

on:
  push:
    tags:
      - v*

env:
  CARGO_TERM_COLOR: always

```

このワークフローは`v`で始まるタグ（例：`v1.0.0`）がプッシュされたときに起動します。
`permissions`セクションでは、GitHub Releasesにファイルをアップロードするために必要な書き込み権限を設定しています。

#### ジョブの連携とテスト実行

```yaml
jobs:
  Test:
    uses: ./.github/workflows/testing.yml

  build:
    needs: [Test]
    # 以下省略

```

リリースプロセスの最初のステップとして、別ファイル（`testing.yml`）で定義されたテストワークフローを実行します。`needs: [Test]`の設定により、テストが成功した場合のみビルドジョブが実行されます。

#### マトリックスビルドによる複数環境対応

```yaml
strategy:
  fail-fast: false
  matrix:
    include:
      - target: x86_64-unknown-linux-gnu
        extension: ""
        runner: ubuntu-latest
        cross: true
      - target: x86_64-pc-windows-msvc
        extension: ".exe"
        runner: windows-latest
        cross: false
      # 他のターゲット設定...

```

マトリックス戦略の真価はここで発揮されます。各ターゲット環境に対して以下の情報を定義しています：

- **target**: Rustのターゲットトリプル
- **extension**: 実行ファイルの拡張子（Windowsの場合は`.exe`）
- **runner**: ビルドを実行するGitHubの環境
- **cross**: crossを使ったクロスコンパイルが必要かどうか

`fail-fast: false`の設定により、一部のビルドが失敗しても他のビルドは継続して実行されるため、可能な限り多くのプラットフォーム向けバイナリを提供できます。

#### 環境に応じたビルドプロセス

```yaml
steps:
  # チェックアウトと依存関係のインストールは省略

  - name: Install cross (if needed)
    if: ${{ matrix.cross }}
    run: cargo install cross --git <https://github.com/cross-rs/cross>

  - name: Build Project on cross
    if: ${{ matrix.cross }}
    run: |
        cross build --release --target ${{ matrix.target }} --verbose
  - name: Build Project
    if: ${{ !matrix.cross }}
    run: |
      rustup target add ${{ matrix.target }}
      cargo build --release --target ${{ matrix.target }} --verbose

```

ビルドプロセスは環境によって異なります：

1. クロスコンパイルが必要な場合（例：Linuxランナーでarm64向けビルド）は、`cross`ツールを使用
2. ネイティブビルドの場合は、`rustup`でターゲットを追加してから`cargo build`を実行

この分岐により、各環境に最適なビルド方法を選択できます。

#### 成果物の管理とリリース

```yaml
- name: Rename Artifacts
  shell: bash
  run: |
    mv target/${{ matrix.target }}/release/${{ env.PROJECT_NAME }}{,-${{ github.ref_name }}-${{ matrix.target }}${{ matrix.extension }}}

- name: Release Artifacts
  uses: softprops/action-gh-release@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    files: |
      target/${{ matrix.target }}/release/${{ env.PROJECT_NAME }}-${{ github.ref_name }}-${{ matrix.target }}${{ matrix.extension }}

```

最後のステップでは、`softprops/action-gh-release`アクションを使用してGitHub Releasesにアップロードします。

このワークフローの実行結果として、リリースページには各プラットフォーム向けのバイナリが自動的に添付され、ユーザーは自分の環境に合ったバイナリを簡単にダウンロードできるようになります。


### cross.toml

今回は、Linuxをターゲットにしたビルドをする際にcrossを使用します。：

```toml
[target.x86_64-unknown-linux-gnu]
image = "ghcr.io/cross-rs/x86_64-unknown-linux-gnu:main-centos"
pre-build = [
    "sed -i /etc/yum.repos.d/*.repo -e 's!^mirrorlist!#mirrorlist!' -e 's!^#baseurl=http://mirror.centos.org/!baseurl=https://vault.centos.org/!'",
    "sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf",
    "yum update -y && yum install -y gcc perl make perl-IPC-Cmd"
]

# 他のターゲット定義...
```

互換性を考慮したコンテナ選択
x86_64およびaarch64ターゲットにはCentOS 7ベースのイメージを指定しています。CentOS 7は古いバージョンのglibcを使用しているため、生成されるバイナリは新しいLinuxディストリビューションと古いディストリビューション両方で動作します。このアプローチはcargoのビルドにも使用されています。

#### リポジトリとパッケージ管理

EOLに達したCentOSを使用する際の注意点として、リポジトリの設定変更が必要です：

```bash
*# ミラーリストをVaultアーカイブに変更*
sed -i /etc/yum.repos.d/*.repo -e 's!^mirrorlist!#mirrorlist!' -e 's!^#baseurl=http://mirror.centos.org/!baseurl=https://vault.centos.org/!'

*# fastestmirrorプラグインを無効化（問題回避のため）*
sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf
```

#### ターゲット固有の設定

armv7アーキテクチャに対しては異なるアプローチを取っています：

```toml
[target.armv7-unknown-linux-gnueabihf]
pre-build = [
    "apt-get update && apt-get install -y crossbuild-essential-armhf",
]
```

このターゲットではDebianベースのイメージを使用し、ARM向けのクロスコンパイルツールチェーンをインストールしています。(armv7用のcentos7イメージが無かった。)
