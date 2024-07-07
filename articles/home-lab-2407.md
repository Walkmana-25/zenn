---
title: "自宅サーバーをはじめてみた"
emoji: "🐙"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["自宅サーバー", "ネットワーク"]
published: false
---

## はじめに

こんにちは。大学1年生のLapisと申します。

今回は現在構築中の自宅サーバーでやりたいことやその構成についての現状をまとめてみました。個人的な挑戦と学びの過程を共有できればと思います。

## やりたいこと

自宅サーバーを構築するにあたり、以下のような目標を設定しました：

1. **仮想基盤の構築**
   - **ネットワーク仮想化**: 自宅インフラとVMのネットワークの完全分離
   - **IaC (Infrastructure as Code)**: インフラ構成のコード化と管理の効率化

2. **Kubernetesクラスターの構築**

3. **マルチゾーン（マルチリージョン）クラウドの構築**

4. **安価で大容量かつ冗長性を確保したストレージの実現**
   - 家にあるさまざまな容量のHDDの有効活用

## 使用するソフトウェア

上記の目標を達成するため、以下のソフトウェアを選択しました：

1. **仮想化基盤: Proxmox**
   - SDNやTerraformの利用可能性
   - 容易な管理と安定稼働の期待

   そのほかにOpenNebulaとMicroStackを検討しましたが、管理コストと必要リソースの観点からProxmoxを採用しました。

2. **分散ストレージシステム: Ceph**
   - 異なる容量のHDDでの冗長性のあるストレージクラスターの構築
   - Proxmoxとの高い親和性

3. **Kubernetes: Rancher管理のRKE2クラスター**
   - 豊富なエコシステムと容易なクラスター管理
   - Istioを使用したマルチリージョン、マルチゾーンクラスターの構築

## 使用機材

1. **L3 Switch: Allied Telesis x510-28gtx**
   - 10G対応かつ安価な入手性

2. **Server: Dell Inspiron 3470**
   - 個人用PCからサーバーへの転用
   - スペック: Intel Core i5-8400, 32GB RAM

3. **Server: HPE ProLiant DL360 Gen 9**
   - ヤフオクでの購入
   - スペック: Intel Xeon E5 2660 v3 x2, 64GB RAM

4. **Server: HPE ProLiant DL160 Gen 9**
   - 友人からの無償レンタル
   - スペック: Intel Xeon E5 2650 v4, 48GB RAM

5. **Server: Raspberry Pi 4 Model B+**
   - Cloudflare TunnelのProxyやUPSの制御用として使用

6. **UPS: APC RS 550**
   - 出力不足のため追加を検討中

## ネットワーク構成

1. **Zero Trust Security Model**の概念をベースとしたネットワーク構成
   - Cloudflare Tunnelを使用した外部からのアクセス管理
   - LAN内での必要最小限のセグメントへのアクセス制限
   - Cloudflare Warpを介したシステム管理時のアクセス
   - Azure IntraID（Azure Active Directory）を利用したアクセス制御の実装

2. **Cloudflare Access**を利用したポート開放なしでのサービス公開

3. **SDN (Software-Defined Networking)**を利用したVM用ネットワークの構築
   - 効率的かつ簡単なセグメント管理の実現

## IaC (Infrastructure as Code)

これまでの自宅サーバー運用での「秘伝のタレ」化問題への対応：

- **運用ルール**:
  - IaCを利用したインフラ管理の最大化
  - コード化不可能な部分の徹底的なドキュメント化

- **VM管理**:
  - VMの構成: Proxmoxの使用
  - Linuxの設定: Ansibleの活用

- **Kubernetes管理**:
  - FluxCDとHelmの使用

## Kubernetes

Kubernetesクラスターの構築にあたり、二種類のクラスターを構築したいと考えています。

### 1. 管理用クラスター

1. **k3sを利用した軽量HAクラスター**
   - リソース効率の良い構成
   - 高可用性（HA）の確保

2. **Rancherの運用**
   - クラスター全体の一元管理
   - ユーザーフレンドリーなインターフェイス

### 2. アプリケーション用クラスター

1. **Rancher ManagedのRKE2クラスター**
   - 堅牢性と拡張性の確保
   - Rancherによる効率的な管理

2. **自作アプリケーションのデプロイ**
   - 友人と共同開発したアプリケーションの運用環境
   - 実践的な学習と経験の場

3. **マルチクラスターシステムの構築**
   - 友人宅のサーバーの活用
   - lstioの利用によるサービスメッシュの実現

## 終わりに

現在構築中の自宅サーバーについて、やりたいことと現状をまとめてみました。今後も自宅サーバーの構築や運用を通じてネットワークやLinuxについての理解を深めていきたいと考えています。この記事が、同じように自宅サーバーに興味を持つ方々の参考になれば幸いです。

## 参考文献

- [Zero Trustセキュリティ | Zero Trustネットワークとは？ Cloudflare](https://www.cloudflare.com/ja-jp/learning/security/glossary/what-is-zero-trust/)
- [ゼロトラスト・セキュリティモデル Wikipedia](https://ja.wikipedia.org/wiki/ゼロトラスト・セキュリティモデル)
