//
//  SettingsView.swift
//  MyHandMemo
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.languageKey) private var language: AppLanguage = .system
    @AppStorage(AppSettings.paperKey) private var defaultPaper: PaperStyle = .ruled
    @AppStorage(AppSettings.penColorKey) private var defaultColor: InkColor = .black
    @AppStorage(AppSettings.penWidthKey) private var defaultWidth: StrokeWidth = .medium

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                group("Display") {
                    NavigationLink(value: AppRoute.language) {
                        HStack {
                            Text("Language")
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            language.title
                                .foregroundStyle(Theme.inkSecondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.disabled)
                        }
                        .font(.system(size: 17))
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                group("Default Paper") {
                    HStack(spacing: 12) {
                        ForEach(PaperStyle.allCases) { style in
                            paperTile(style)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }

                group("Default Pen") {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Color")
                            Spacer()
                            HStack(spacing: 4) {
                                ForEach(InkColor.allCases) { color in
                                    ColorSwatchButton(color: color, isSelected: defaultColor == color,
                                                      dotSize: 26) {
                                        defaultColor = color
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))
                        .frame(minHeight: 60)
                        Rectangle()
                            .fill(Theme.rowDivider)
                            .frame(height: 1)
                            .padding(.leading, 16)
                        HStack {
                            Text("Width")
                            Spacer()
                            HStack(spacing: 6) {
                                ForEach(StrokeWidth.allCases) { width in
                                    WidthOptionButton(width: width, color: defaultColor,
                                                      isSelected: defaultWidth == width,
                                                      barWidth: 34, buttonWidth: 56) {
                                        defaultWidth = width
                                    }
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 12))
                        .frame(minHeight: 60)
                    }
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.ink)
                }

                group(nil) {
                    HStack {
                        Text("Version")
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text(verbatim: version)
                            .foregroundStyle(Theme.inkSecondary)
                    }
                    .font(.system(size: 17))
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 22)
            .padding(.bottom, 32)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private func group<Content: View>(_ title: LocalizedStringKey?,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.inkSecondary)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 7)
            }
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    /// 用紙は名前ではなく実物の見た目で選ばせる
    private func paperTile(_ style: PaperStyle) -> some View {
        let isSelected = defaultPaper == style
        return Button {
            defaultPaper = style
        } label: {
            VStack(spacing: 8) {
                PaperBackground(style: style, pitch: 14)
                    .frame(height: 74)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? Theme.accent : Theme.separator,
                                          lineWidth: isSelected ? 2 : 1)
                    )
                Text(style.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// 表示言語の選択。選んだ時点でアプリ全体の表示が切り替わる。
struct LanguageSettingsView: View {
    @AppStorage(AppSettings.languageKey) private var language: AppLanguage = .system

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(AppLanguage.allCases) { option in
                    if option != AppLanguage.allCases.first {
                        Rectangle()
                            .fill(Theme.rowDivider)
                            .frame(height: 1)
                            .padding(.leading, 16)
                    }
                    Button {
                        language = option
                    } label: {
                        HStack {
                            option.title
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            if language == option {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                        .font(.system(size: 17))
                        .padding(.horizontal, 16)
                        .frame(height: 50)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(language == option ? .isSelected : [])
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 22)
        }
        .background(Theme.groupedBackground.ignoresSafeArea())
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
