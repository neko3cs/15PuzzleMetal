# 15PuzzleMetal

SwiftとMetalを使用して実装された、macOS向けの15パズルゲーム（スライドパズル）です。ポップでビビッドなデザインと、モダンなアーキテクチャを採用しています。

![15PuzzleMetal](docs/15PuzzleMetal.gif)

## 特徴

- **ビビッドなデザイン**: プラスチックのような光沢感のあるタイルと、鮮やかなカラーパレットを採用。
- **システムテーマ同期**: macOSのライトモード・ダークモード設定にリアルタイムで背景色が同期します。
- **モダンな設計**: MVCアーキテクチャに基づいたクリーンな設計と、Swift 6の並行性（Concurrency）に完全対応。
- **高画質レンダリング**: Metalによるハードウェア加速と、アルファブレンディング、ミップマッピングにより、滑らかでジャギのない描画を実現しています。

## 操作方法

### パネルの移動

空白のパネルを以下のキーで移動させることができます：

- **十字キー** (↑, ↓, ←, →)
- **hjkl キー** (Vim形式）
  - `h`: 左
  - `j`: 下
  - `k`: 上
  - `l`: 右

### ゲームのリセット

- **Cmd + R** を押すか、メニューバーの **Game > Reset** を選択してください。

### クリア条件

タイルを1から15まで順番に並べるとクリアです。クリア時には "You did it!" というメッセージが表示されます。

## 技術スタック

- **Language**: Swift 6
- **Graphics API**: Metal
- **Framework**: AppKit (MetalKit)
- **Architecture**: MVC (Model-View-Controller)
- **Unit Testing**: Swift Testing

## ディレクトリ構造

- `15PuzzleMetal/Models`: ゲームロジックとデータ
- `15PuzzleMetal/Views`: Metalレンダラー、シェーダー、テクスチャ生成
- `15PuzzleMetal/Controllers`: 入力処理と各コンポーネントの仲介
- `15PuzzleMetalTests`: ユニットテストコード

## ライセンス

[MIT License](LICENSE)
