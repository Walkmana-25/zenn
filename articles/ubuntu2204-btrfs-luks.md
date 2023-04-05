---
title: "Ubuntu22.04をWindows11と共存させながらゲーミングノートPCにインストールする"
emoji: "✨"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["ubuntu", "windows","linux","btrfs","luks"]
published: false
---

## はじめに

マウスコンピューターのゲーミングノートPC G-Tune E5-165を入手しました。主に開発目的で使用する予定ですが、ゲームも楽しみたいと思い、デュアルブート構成でインストールしました。しかし、セキュアブートやファイルシステム関連で苦労したため、今回の手順を忘備録として残しておこうと思います。

### 要件

#### PCのスペック

- デフォルトOS: Windows11 Home 64bit
- CPU: Intel Core i7 12700H 14C20T
- Memory: DDR5 4800 16GB（32GBに増設）
- Storage: 512GB NVMESSD（もう一台512GBのSSDを増設）  
- GPU: Nvidia RTX 3060 Laptop  
- Windows Hello: 顔認証
