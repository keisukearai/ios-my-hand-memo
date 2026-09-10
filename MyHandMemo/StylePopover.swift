//
//  StylePopover.swift
//  MyHandMemo
//

import SwiftUI

struct InkSettings: Equatable {
    var color: InkColor
    var width: StrokeWidth
}

/// 色と太さを1つにまとめたポップオーバー（CanvasToolOpen）
struct StylePopover: View {
    @Binding var ink: InkSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("Color")
            HStack(spacing: 10) {
                ForEach(InkColor.allCases) { color in
                    ColorSwatchButton(color: color, isSelected: ink.color == color, dotSize: 28) {
                        ink.color = color
                    }
                }
            }
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
                .padding(.top, 12)
                .padding(.bottom, 10)
            sectionTitle("Width")
            HStack(spacing: 10) {
                ForEach(StrokeWidth.allCases) { width in
                    WidthOptionButton(width: width, color: ink.color, isSelected: ink.width == width,
                                      barWidth: 64, buttonWidth: nil) {
                        ink.width = width
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 12, leading: 14, bottom: 14, trailing: 14))
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.separator))
        .shadow(color: Theme.ink.opacity(0.18), radius: 14, y: 10)
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.inkSecondary)
            .padding(.bottom, 6)
    }
}

/// 色の選択肢。色は名前ではなく実物の色で見せる。
struct ColorSwatchButton: View {
    let color: InkColor
    let isSelected: Bool
    let dotSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color.color)
                .frame(width: dotSize, height: dotSize)
                .frame(width: 44, height: 44)
                .background {
                    if isSelected {
                        Circle().fill(Theme.accentFill)
                        Circle().strokeBorder(Theme.accent, lineWidth: 2)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(color.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// 太さの選択肢。実際の線の太さで見せる。
struct WidthOptionButton: View {
    let width: StrokeWidth
    let color: InkColor
    let isSelected: Bool
    let barWidth: CGFloat
    /// nil のときは横いっぱいに広げる
    let buttonWidth: CGFloat?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Capsule()
                .fill(color.color)
                .frame(width: barWidth, height: width.points)
                .frame(maxWidth: buttonWidth ?? .infinity)
                .frame(width: buttonWidth, height: 44)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12).fill(Theme.accentFill)
                        RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.accent, lineWidth: 2)
                    }
                }
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(width.title))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
