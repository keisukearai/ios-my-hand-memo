//
//  MyHandMemoApp.swift
//  MyHandMemo
//
//  Created by keisuke arai on 2026/09/11.
//

import SwiftData
import SwiftUI

@main
struct MyHandMemoApp: App {
    @AppStorage(AppSettings.languageKey) private var language: AppLanguage = .system

    /// UI テストは毎回まっさらな状態から始めたいので、保存先をメモリ内に切り替える
    private let isUITesting = ProcessInfo.processInfo.arguments.contains("-uiTesting")

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.locale, language.locale)
        }
        .modelContainer(for: Note.self, inMemory: isUITesting)
    }
}
