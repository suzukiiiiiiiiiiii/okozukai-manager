# APK のダウンロードとインストール手順

このリポジトリは GitHub Actions を使って自動的に Android 用の APK ファイル（`app-release.apk`）をビルドします。

## 1. GitHub Releases から直接ダウンロードする場合（おすすめ）

1. GitHub リポジトリページの右側（スマホの場合は下の方）にある **Releases** を開きます。
2. 最新の `お小遣い管理 APK` リリースの **Assets** にある `app-release.apk` をタップしてダウンロードします。
3. ダウンロードした APK を開き、Android の「提供元不明のアプリのインストール」を許可してインストールします。

## 2. Actions タブの Artifacts からダウンロードする場合

1. リポジトリ上部の **Actions** タブを開きます。
2. 一番上の緑色のチェックがついた **Build APK** ワークフロー実行結果をタップします。
3. ページ下部の **Artifacts** にある `okozukai-manager-apk` をダウンロードし、ZIP を解凍して中の `app-release.apk` をインストールします。
