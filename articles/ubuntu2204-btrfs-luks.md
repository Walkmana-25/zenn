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

#### PCの詳細について

Column A | Column B | Column C
---------|----------|---------
 A1 | B1 | C1
 A2 | B2 | C2
 A3 | B3 | C3
