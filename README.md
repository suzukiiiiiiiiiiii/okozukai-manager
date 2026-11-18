# お小遣い・収支管理 (Okozukai Manager)

現金だけでなく電子決済（PayPay・Suicaなど）・銀行口座・クレジットカードにも対応し、**固定引き落とし・固定収入**や**「◯ヶ月この金額で生活するには一日いくらまで」の生活目安シミュレーション**ができる Android 向けお小遣い管理アプリです。

## 主な機能

- **現金＋電子決済・口座・カードのマルチウォレット管理**
  - 現金（財布）、QR・バーコード決済（PayPay、楽天ペイ等）、電子マネー・交通系IC（Suica、PASMO等）、銀行口座、クレジットカードを個別に管理
  - **チャージ・口座間振替**（例：銀行口座からPayPayにチャージ、現金からSuicaにチャージ）に対応し、総資産を狂わせずに各決済手段の残高を正確に追跡
- **固定引き落とし・固定収入（定期収支）の自動・手動管理**
  - 毎月の固定収入（お小遣い、仕送り、給料、バイト代等）と固定引き落とし（通信費・スマホ代、動画/音楽サブスク、家賃、光熱費等）を登録可能
  - 毎月の指定日（1〜28日または月末）が到来した際の自動計上モードと、ワンタップ「今すぐ計上」に対応
- **かんたん記録 ＆「何にいくら使ったか」の可視化**
  - よく使う支出（コンビニ、ランチ、カフェ、電車代など）を**1タップで即座に記録**できるクイックテンプレート機能
  - 月ごとの**カテゴリ別支出ランキング・割合グラフ**と**決済手段別（現金 vs 電子決済等）の支出内訳**をひと目で把握
  - カテゴリ・決済手段・種別フィルタやキーワード検索に対応した履歴タイムライン
- **「◯ヶ月この金額で生活するには一日いくらまで」生活目安シミュレーター**
  - 現在の残高合計（または任意の指定金額）で **半月・1ヶ月・2ヶ月・3ヶ月・6ヶ月・1年（または1〜365日の任意日数）** 生活する場合の**1日あたり上限額・1週間換算・今日あと使える残り金額**をリアルタイム算出
  - 期間中に発生する**固定引き落としの差し引き**・**固定収入の加算**・**最後に残したい予備費（目標貯金額）**のON/OFF切り替えに対応
  - 1ヶ月〜1年の期間別比較早見表と、直近14日間の支出ペースから「今のペースだとあと何日持つか」を診断

## リポジトリ構成

```
pubspec.yaml
README.md
.gitignore
analysis_options.yaml
android_config/AndroidManifest.xml
docs/APKの作り方.md
.github/workflows/build.yml
lib/
  main.dart
  models.dart
  finance_store.dart
  app_theme.dart
  formatters.dart
  screens/
    main_shell.dart
    dashboard_screen.dart
    transactions_screen.dart
    simulator_screen.dart
    wallets_screen.dart
  widgets/
    add_transaction_sheet.dart
    add_wallet_sheet.dart
    add_recurring_sheet.dart
test/
  finance_store_test.dart
```

## GitHub Actions による APK 自動ビルド

`main` ブランチへ push すると、`.github/workflows/build.yml` が自動的に起動し、以下を実行します：

1. `flutter create --platforms=android` で Android プロジェクト骨格を生成し、`android_config/AndroidManifest.xml` を適用
2. `flutter analyze --no-fatal-infos` と `flutter test` で静的解析・単体テストを実行
3. `flutter build apk --release --no-shrink` でリリース APK をビルド
4. Actions の **Artifacts (`okozukai-manager-apk`)** および **GitHub Releases** に `app-release.apk` を自動公開
