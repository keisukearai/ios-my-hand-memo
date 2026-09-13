# MyHandMemo

指で走り書きするだけの手書きメモ帳（iOS）。デザインは Claude Design プロジェクト「MyHandMemo UI.dc.html」（projectId: 790e3cf4-92fa-4924-a3ea-dbe2af170567）。

## 前提
- iPhone のみ / iOS 18.0 以上 / 縦固定 / ライトモード固定
- 審査提出済み（2026-09-12）。まだ公開前
- バンドル ID は `com.keisukearai.MyHandMemo` で確定（2026-09-12）。App Store Connect で App を作ると変更できない
  - Capability を一つも使っていないため Xcode の自動署名はワイルドカード App ID（`HFZSU3MJLR.*`）を使う。
    App Store Connect のバンドル ID 一覧には明示的な App ID しか出ないので、開発者ポータルでの登録が別途必要
- 言語: 英語（開発言語）＋日本語。文字列は `Localizable.xcstrings`（キーは英語）
- ファイルは Xcode の自動同期グループ。追加・削除で pbxproj の編集は不要

## 技術構成
- SwiftUI + SwiftData（`Note` モデル）+ PencilKit
- 既定の用紙・ペンの色・太さは `@AppStorage`（キーは `AppSettings`）
- 配色・寸法は `Theme.swift` にデザインのトークンをそのまま定義

## 決定事項
- 描画は PencilKit。標準のツールピッカーは使わず、自作ツールバー（ペン / マーカー / 消しゴム / 色と太さ / …）
- ホームの見出しは「手書きメモ / Handwritten Notes」をナビバー内に左寄せ（20pt・太字、大きいタイトルは使わない）
  - `.navigationTitle` は戻るボタンの文言用に残し、`.toolbar(removing: .title)` で表示だけ消す
  - iOS 26 では見出しにガラス調の背景が付かないよう `.sharedBackgroundVisibility(.hidden)` を付ける
- キャンバスは1画面分で固定（スクロールなし）
- キャンバス画面はナビゲーションバーと戻るボタンを隠す（端から書いたとき、スワイプで戻る操作と取り合わないように）
- `NoteCanvasView` はメモごとに専用の UndoManager を持つ（ウィンドウ共有の UndoManager と混ぜない）
- 新規メモは最初の1画を書くまで保存しない。空のまま戻ったメモは削除する
- サムネイルは保存時に上部4:3を用紙込みで PNG にしてモデルに保存
- 全消去は確認なし＋5秒の「元に戻す」トースト。メモの削除は確認シートを出す
- 表示言語はアプリ内で切り替える（端末に合わせる / 日本語 / English、初期値は端末に合わせる）
  - `@AppStorage("appLanguage")` の値で、アプリの一番外側の環境値 `\.locale` を差し替え、その場で反映する
  - 日付は環境値 `locale` で書式化する（`Locale.current` を使うと切り替わらない）
  - 共有シートなど iOS が出す部品は端末の言語のまま（この方式の制約）

## テスト
- UI テストは `MyHandMemoUITests`。`xcodebuild test -scheme MyHandMemo -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
  - 実機は `-destination 'platform=iOS,name=arai13' -allowProvisioningUpdates`
  - テスト中は起動引数 `-uiTesting` で SwiftData をメモリ内にし、毎回空から始める
- `ShareSaveImageUITests` は写真ライブラリへ実際に書き込む。混ぜたくないときは
  `-skip-testing:MyHandMemoUITests/ShareSaveImageUITests`
- シミュレータ・実機の両方で確認済み：指描画・Undo/Redo・全消去からの復元・空メモの非保存・
  長押しメニュー（固定/複製/削除）・英語表示・共有シートからの画像保存

## 未検証
- 実機での書き味そのもの（XCUITest のドラッグは等速の直線で、筆圧も傾きも無い）
- iOS 26 の画面全体スワイプで戻る操作が、キャンバス上で無効になっているか
- iOS 18 での見た目全般（シミュレータに iOS 26.5 しか入っていない）

## App Store
- メタデータ・スクショ・年齢制限は fastlane で管理（`fastlane/`）
  - `bundle exec fastlane <lane> --env local`。Homebrew の Ruby を使う（`PATH=/opt/homebrew/opt/ruby/bin:$PATH`）
  - `.env.local` は gitignore 済み。API キーは MyTapCount と同じものを使う
- レーン: `upload_metadata`（テキスト＋年齢制限）/ `upload_screenshots` / `prepare_submission`（配信権・輸出コンプライアンス）/ `set_price_free`
- スクショは `./fastlane/capture_screenshots.sh` で 1284x2778 が日英 5 枚ずつ。
  見本メモは `-seedSampleData`（`SampleData.swift`、`#if DEBUG`）
- バイナリのアップロードだけは Xcode の Organizer から手動

### 注意
- **deliver の `price_tier` は使えない。** Apple が価格 API を作り替えていて
  `'prices' is not a relationship on the resource 'apps'` で落ちる。
  `set_price_free` は新しい `appPriceSchedules` / `appPricePoints` を直に叩いている
- 年齢制限の `ageAssurance` は API が必須にしている。無いと弾かれる
- 配信権と輸出コンプライアンスは deliver の `submission_information` では
  `submit_for_review: true` のときしか送られない。提出前に入れたいので `prepare_submission` で spaceship を直に叩く
- 暗号化は使っていないので `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` を入れてある。
  以後アップロードするビルドでは輸出コンプライアンスを訊かれない
- **`InfoPlist.xcstrings` のキーには `en` の訳も必ず入れる。** 無いと en.lproj/InfoPlist.strings に
  キー名がそのまま値として入り、pbxproj の `INFOPLIST_KEY_...` を上書きする。
  1.0 (1) は `NSPhotoLibraryAddUsageDescription` がプレースホルダー扱いで審査に通らなかった（2026-09-14）
- プライバシーポリシーは `docs/privacy-{ja,en}.md`。掲載先は https://kotoragk.com/myhandmemo/privacy
