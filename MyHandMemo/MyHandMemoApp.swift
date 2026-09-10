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

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.locale, language.locale)
        }
        .modelContainer(for: Note.self)
    }
}
