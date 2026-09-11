//
//  ShareSaveImageUITests.swift
//  MyHandMemoUITests
//
//  共有シートの「画像を保存」を押す経路だけを確かめる。
//  写真ライブラリへ実際に書き込むため、他のテストとは分けてある。
//  NSPhotoLibraryAddUsageDescription が無いとここでアプリが落ちる。
//

import XCTest

final class ShareSaveImageUITests: XCTestCase {
    private var app: XCUIApplication!

    private var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-uiTesting",
            "-appLanguage", "en",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testSaveImageFromShareSheetDoesNotCrash() throws {
        makeNote()

        noteCards.element(boundBy: 0).press(forDuration: 1.2)

        let share = app.buttons["Share as Image"]
        XCTAssertTrue(share.waitForExistence(timeout: 3), "長押しメニューに Share as Image が無い")
        share.tap()

        // 共有シートは端末の言語で出ることがあるので、英語と日本語の両方を見る
        let saveImage = anyElement(labels: ["Save Image", "画像を保存"])
        XCTAssertTrue(waitUntil(timeout: 15) { saveImage() != nil },
                      "共有シートに「画像を保存」が見つからない")
        saveImage()?.tap()

        // 写真への追加を訊かれたら許可する（初回のみ出る）
        allowPhotoAccessIfAsked()

        // ここで落ちていなければ NSPhotoLibraryAddUsageDescription が効いている
        XCTAssertTrue(waitUntil(timeout: 15) { self.app.state == .runningForeground },
                      "「画像を保存」でアプリが落ちた（または前面に戻らない）")
        XCTAssertEqual(app.state, .runningForeground, "保存後にアプリが動いていない")

        // 一覧まで戻れることまで見る
        app.swipeDown()
        XCTAssertTrue(waitUntil(timeout: 10) { self.noteCards.count >= 1 },
                      "共有シートを閉じたあと一覧に戻れない")
    }

    // MARK: - ヘルパー

    private var noteCards: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Note, "))
    }

    private func makeNote() {
        let newNote = app.buttons["New Note"]
        XCTAssertTrue(newNote.waitForExistence(timeout: 5), "新規メモボタンが出ない")
        newNote.tap()
        XCTAssertTrue(app.buttons["Back"].waitForExistence(timeout: 5), "キャンバスが開かない")

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.4))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.55))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)

        app.buttons["Back"].tap()
        XCTAssertTrue(waitUntil(timeout: 10) { self.noteCards.count >= 1 }, "メモを用意できなかった")
    }

    /// 共有シートは app 側にも springboard 側にも出うるので、両方から探す
    private func anyElement(labels: [String]) -> () -> XCUIElement? {
        let predicate = NSPredicate(format: "label IN %@", labels)
        return {
            for root in [self.app!, self.springboard] {
                for query in [root.buttons, root.cells, root.staticTexts] {
                    let hit = query.matching(predicate).firstMatch
                    if hit.exists && hit.isHittable { return hit }
                }
            }
            return nil
        }
    }

    private func allowPhotoAccessIfAsked() {
        let allow = anyElement(labels: ["Allow", "OK", "許可", "追加のみ許可", "Allow Access to All Photos"])
        _ = waitUntil(timeout: 5) { allow() != nil }
        allow()?.tap()
    }

    @discardableResult
    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            _ = XCUIApplication().wait(for: .runningForeground, timeout: 0.3)
        }
        return condition()
    }
}
