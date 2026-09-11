//
//  ScreenshotUITests.swift
//  MyHandMemoUITests
//
//  App Store 用のスクリーンショットを撮る。撮影は fastlane/capture_screenshots.sh から。
//  撮った画像は XCTAttachment として結果バンドルに入り、スクリプト側で取り出す。
//
//  言語は環境変数 SHOT_LANG（ja / en）で切り替える。
//

import XCTest

final class ScreenshotUITests: XCTestCase {
    private var app: XCUIApplication!
    private var lang: String { ProcessInfo.processInfo.environment["SHOT_LANG"] ?? "en" }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-seedSampleData",
            "-appLanguage", lang,
            "-AppleLanguages", "(\(lang))",
            "-AppleLocale", lang == "ja" ? "ja_JP" : "en_US",
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testCaptureAll() throws {
        // 1. 一覧
        XCTAssertTrue(waitUntil(timeout: 20) { self.noteCards.count >= 6 },
                      "見本データが入っていない")
        settle()
        shot("01_home")

        // 2. 長押しメニュー
        center(of: noteCards.element(boundBy: 1)).press(forDuration: 1.2)
        XCTAssertTrue(app.buttons[label(ja: "複製", en: "Duplicate")].waitForExistence(timeout: 5),
                      "長押しメニューが出ない")
        settle()
        shot("02_menu")
        // メニューは画面下の空きを突いて閉じる
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.93)).tap()
        settle()

        // 3. キャンバス
        center(of: noteCards.element(boundBy: 0)).tap()
        XCTAssertTrue(app.buttons[label(ja: "戻る", en: "Back")].waitForExistence(timeout: 5),
                      "キャンバスが開かない")
        settle()
        shot("03_canvas")

        // 4. 色と太さ
        app.buttons[label(ja: "色と太さ", en: "Color & Width")].tap()
        XCTAssertTrue(app.staticTexts[label(ja: "太さ", en: "Width")].waitForExistence(timeout: 5),
                      "色と太さが開かない")
        settle()
        shot("04_style")
        app.buttons[label(ja: "色と太さ", en: "Color & Width")].tap()
        app.buttons[label(ja: "戻る", en: "Back")].tap()

        // 5. 設定
        XCTAssertTrue(app.buttons[label(ja: "設定", en: "Settings")].waitForExistence(timeout: 5))
        app.buttons[label(ja: "設定", en: "Settings")].tap()
        XCTAssertTrue(app.staticTexts[label(ja: "用紙", en: "Paper")].waitForExistence(timeout: 5)
                        || app.staticTexts[label(ja: "表示言語", en: "Language")].exists,
                      "設定が開かない")
        settle()
        shot("05_settings")
    }

    // MARK: - ヘルパー

    private var noteCards: XCUIElementQuery {
        let prefix = lang == "ja" ? "メモ、" : "Note, "
        return app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix))
    }

    private func label(ja: String, en: String) -> String {
        lang == "ja" ? ja : en
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "\(lang)_\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// アニメーションが終わるのを待つ。スクショなので落ち着いた絵が要る
    private func settle() {
        Thread.sleep(forTimeInterval: 1.2)
    }

    private func center(of element: XCUIElement) -> XCUICoordinate {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            _ = app.wait(for: .runningForeground, timeout: 0.3)
        }
        return condition()
    }
}
