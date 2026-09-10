//
//  Theme.swift
//  MyHandMemo
//

import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// デザインのトークン（Light only）
enum Theme {
    static let backgroundUI = UIColor(hex: 0xF6F3ED)
    static let surfaceUI = UIColor(hex: 0xFFFCF6)
    static let paperLineUI = UIColor(hex: 0xDDD6C8)

    static let background = Color(backgroundUI)
    static let surface = Color(surfaceUI)
    static let paperLine = Color(paperLineUI)
    static let ink = Color(UIColor(hex: 0x221F1B))
    static let inkSecondary = Color(UIColor(hex: 0x8B8377))
    static let accent = Color(UIColor(hex: 0x2F4FA0))
    static let accentFill = accent.opacity(0.12)
    static let destructive = Color(UIColor(hex: 0xD14336))
    static let separator = Color(UIColor(hex: 0xE2DCD1))
    static let cardDivider = Color(UIColor(hex: 0xEDE7DC))
    static let rowDivider = Color(UIColor(hex: 0xE7E1D6))
    static let disabled = Color(UIColor(hex: 0xC3BCAF))
    static let groupedBackground = Color(UIColor(hex: 0xF1EEE7))
    static let emptyIllustration = Color(UIColor(hex: 0xC9C0AE))

    /// 罫線・方眼のピッチ（キャンバス上）
    static let paperPitch: CGFloat = 36
}
