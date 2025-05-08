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

