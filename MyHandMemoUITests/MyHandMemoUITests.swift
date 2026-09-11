//
//  MyHandMemoUITests.swift
//  MyHandMemoUITests
//

import XCTest

final class MyHandMemoUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // 表示言語を英語に固定してラベルで要素を引けるようにする。
        // ストアはメモリ内（-uiTesting）なのでテストごとにメモは空から始まる。
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

    // MARK: - ホーム

    func testEmptyStateShowsPrompt() throws {
        XCTAssertTrue(app.staticTexts["Tap the pencil to start writing"].waitForExistence(timeout: 5),
                      "空状態の案内文が出ていない")
        XCTAssertTrue(newNoteButton.exists, "新規メモボタンが無い")
        XCTAssertTrue(app.buttons["Settings"].exists, "設定ボタンが無い")
        XCTAssertEqual(noteCards.count, 0, "初期状態でメモが残っている")
    }

    // MARK: - キャンバス

    func testCanvasShowsToolbarAndBackButton() throws {
        openNewNote()

        for label in ["Back", "Undo", "Redo", "Pen", "Marker", "Eraser", "Color & Width", "More"] {
            XCTAssertTrue(app.buttons[label].exists, "ツールバーに \(label) が無い")
        }
        // ナビゲーションバーは隠している
        XCTAssertFalse(app.navigationBars.firstMatch.exists, "キャンバスでナビゲーションバーが出ている")
    }

    func testDrawStrokeEnablesUndoThenRedo() throws {
        openNewNote()

        let undo = app.buttons["Undo"]
        let redo = app.buttons["Redo"]
        XCTAssertFalse(undo.isEnabled, "描く前から Undo が有効")
        XCTAssertFalse(redo.isEnabled, "描く前から Redo が有効")

        drawStroke()

        XCTAssertTrue(waitUntil { undo.isEnabled }, "描いた後も Undo が無効のまま")

        undo.tap()
        XCTAssertTrue(waitUntil { redo.isEnabled }, "Undo 後に Redo が有効にならない")
        XCTAssertTrue(waitUntil { !undo.isEnabled }, "1画を戻したのに Undo がまだ有効")

        redo.tap()
        XCTAssertTrue(waitUntil { undo.isEnabled }, "Redo 後に Undo が有効にならない")
    }

    func testToolSelectionSwitches() throws {
        openNewNote()

        let pen = app.buttons["Pen"]
        let marker = app.buttons["Marker"]
        let eraser = app.buttons["Eraser"]

        marker.tap()
        XCTAssertTrue(marker.isHittable, "マーカーを選べない")
        eraser.tap()
        XCTAssertTrue(eraser.isHittable, "消しゴムを選べない")
        pen.tap()
        XCTAssertTrue(pen.isHittable, "ペンに戻せない")
    }

    func testStylePopoverOpens() throws {
        openNewNote()

        app.buttons["Color & Width"].tap()

        // StylePopover は overlay で出す自作ビューなので、中身の要素で開閉を判定する
        XCTAssertTrue(app.staticTexts["Color"].waitForExistence(timeout: 3), "色のセクションが出ない")
        XCTAssertTrue(app.staticTexts["Width"].exists, "太さのセクションが出ない")
        for width in ["Thin", "Medium", "Thick"] {
            XCTAssertTrue(app.buttons[width].exists, "太さの選択肢 \(width) が無い")
        }

        app.buttons["Thick"].tap()
        // もう一度押すと閉じる
        app.buttons["Color & Width"].tap()
        XCTAssertTrue(waitUntil { !self.app.staticTexts["Color"].exists }, "ポップオーバーが閉じない")
    }

    func testClearAllShowsUndoToast() throws {
        openNewNote()
        drawStroke()

        app.buttons["More"].tap()
        let clear = app.buttons["Clear All"]
        XCTAssertTrue(clear.waitForExistence(timeout: 3), "「…」メニューに Clear All が無い")
        clear.tap()

        XCTAssertTrue(app.staticTexts["Cleared"].waitForExistence(timeout: 3), "全消去のトーストが出ない")

        let toastUndo = app.buttons["Undo"].firstMatch
        XCTAssertTrue(toastUndo.exists, "トーストの Undo が無い")
        toastUndo.tap()
        XCTAssertTrue(waitUntil { self.app.buttons["Undo"].isEnabled }, "全消去を取り消せていない")
    }

    // MARK: - 保存

    func testDrawnNoteIsSavedAndEmptyNoteIsNot() throws {
        // 1画書いて戻る → カードが1枚増える
        openNewNote()
        drawStroke()
        app.buttons["Back"].tap()
        XCTAssertTrue(waitUntil { self.noteCards.count == 1 }, "描いたメモが保存されていない")

        // 何も書かずに戻る → 増えない
        newNoteButton.tap()
        XCTAssertTrue(app.buttons["Back"].waitForExistence(timeout: 5))
        app.buttons["Back"].tap()
        XCTAssertTrue(waitUntil { self.noteCards.count == 1 }, "空のメモが保存されてしまっている")
    }

    func testNoteCanBeDeletedFromContextMenu() throws {
        makeNote()
        XCTAssertEqual(noteCards.count, 1)

        noteCards.element(boundBy: 0).press(forDuration: 1.2)

        let delete = app.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 3), "長押しメニューに Delete が無い")
        delete.tap()

        // 確認シート
        let confirm = app.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3), "削除の確認シートが出ない")
        confirm.tap()

        XCTAssertTrue(waitUntil { self.noteCards.count == 0 }, "メモが削除されていない")
        XCTAssertTrue(app.staticTexts["Tap the pencil to start writing"].waitForExistence(timeout: 3))
    }

    func testNoteCanBePinnedAndDuplicated() throws {
        makeNote()

        noteCards.element(boundBy: 0).press(forDuration: 1.2)
        let pin = app.buttons["Pin"]
        XCTAssertTrue(pin.waitForExistence(timeout: 3), "長押しメニューに Pin が無い")
        pin.tap()
        XCTAssertTrue(waitUntil { self.noteCards.element(boundBy: 0).value as? String == "Pinned" },
                      "ピン留めが反映されていない")

        noteCards.element(boundBy: 0).press(forDuration: 1.2)
        let duplicate = app.buttons["Duplicate"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 3), "長押しメニューに Duplicate が無い")
        duplicate.tap()
        XCTAssertTrue(waitUntil { self.noteCards.count == 2 }, "複製されていない")
    }

    // MARK: - 設定

    func testSettingsShowsSections() throws {
        app.buttons["Settings"].tap()

        for label in ["Language", "Color", "Width", "Version"] {
            XCTAssertTrue(app.staticTexts[label].waitForExistence(timeout: 3), "設定に \(label) が無い")
        }
    }

    func testLanguageScreenListsOptions() throws {
        app.buttons["Settings"].tap()

        // 行そのもの（NavigationLink のボタン）を押す。文字だけ押しても遷移しない
        let languageRow = app.buttons.containing(.staticText, identifier: "Language").firstMatch
        XCTAssertTrue(languageRow.waitForExistence(timeout: 3), "言語の行が無い")
        languageRow.tap()

        // 一覧の各行はボタン。ここにだけ出る「Match Device」で遷移を確かめる
        XCTAssertTrue(app.buttons["Match Device"].waitForExistence(timeout: 3), "言語一覧に遷移していない")
        XCTAssertTrue(app.buttons["日本語"].exists, "言語一覧に 日本語 が無い")

        let english = app.buttons["English"]
        XCTAssertTrue(english.exists, "言語一覧に English が無い")
        XCTAssertTrue(english.isSelected, "起動引数で英語にしたのに English が選択状態でない")
    }

    // MARK: - ヘルパー

    private var newNoteButton: XCUIElement { app.buttons["New Note"] }

    private var noteCards: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Note, "))
    }

    private func openNewNote() {
        XCTAssertTrue(newNoteButton.waitForExistence(timeout: 5), "新規メモボタンが出ない")
        newNoteButton.tap()
        XCTAssertTrue(app.buttons["Back"].waitForExistence(timeout: 5), "キャンバスが開かない")
    }

    /// 1画書いて保存されたメモを1枚作る
    private func makeNote() {
        openNewNote()
        drawStroke()
        app.buttons["Back"].tap()
        XCTAssertTrue(waitUntil { self.noteCards.count >= 1 }, "メモを用意できなかった")
    }

    /// キャンバス中央あたりを指でなぞる
    private func drawStroke() {
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.4))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.55))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
    }

    private func waitUntil(timeout: TimeInterval = 5, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            _ = XCUIApplication().wait(for: .runningForeground, timeout: 0.2)
        }
        return condition()
    }
}
