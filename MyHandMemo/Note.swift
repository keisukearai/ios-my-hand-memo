//
//  Note.swift
//  MyHandMemo
//

import Foundation
import SwiftData
import SwiftUI
import UIKit

@Model
final class Note {
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    var isPinned: Bool = false
    var paperRaw: String = PaperStyle.ruled.rawValue
    /// PKDrawing.dataRepresentation()
    @Attribute(.externalStorage) var drawingData: Data = Data()
    /// 上部4:3を切り出したサムネイル（PNG、用紙込み）
    @Attribute(.externalStorage) var thumbnailData: Data?
    /// 描いたときのキャンバスの大きさ（共有画像の書き出しに使う）
    var canvasWidth: Double = 0
    var canvasHeight: Double = 0

    init(paper: PaperStyle) {
        self.paperRaw = paper.rawValue
    }

    var paper: PaperStyle {
        get { PaperStyle(rawValue: paperRaw) ?? .ruled }
        set { paperRaw = newValue.rawValue }
    }

    func duplicated() -> Note {
        let copy = Note(paper: paper)
        copy.drawingData = drawingData
        copy.thumbnailData = thumbnailData
        copy.canvasWidth = canvasWidth
        copy.canvasHeight = canvasHeight
        return copy
    }
}

enum PaperStyle: String, CaseIterable, Identifiable {
    case plain, ruled, grid

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .plain: "Plain"
        case .ruled: "Ruled"
        case .grid: "Grid"
        }
    }

    /// 用紙の線を塗りつぶす矩形。SwiftUI 表示と画像書き出しで同じ線を使うために共通化している。
    func lineRects(in size: CGSize, pitch: CGFloat, lineWidth: CGFloat = 1) -> [CGRect] {
        let horizontals = stride(from: pitch - lineWidth, to: size.height, by: pitch).map {
            CGRect(x: 0, y: $0, width: size.width, height: lineWidth)
        }
        switch self {
        case .plain:
            return []
        case .ruled:
            return horizontals
        case .grid:
            let verticals = stride(from: pitch - lineWidth, to: size.width, by: pitch).map {
                CGRect(x: $0, y: 0, width: lineWidth, height: size.height)
            }
            return horizontals + verticals
        }
    }
}

enum InkColor: String, CaseIterable, Identifiable {
    case black, blue, red, yellow

    var id: Self { self }

    var uiColor: UIColor {
        switch self {
        case .black: UIColor(hex: 0x1A1A1A)
        case .blue: UIColor(hex: 0x1F4FD8)
        case .red: UIColor(hex: 0xE0332B)
        case .yellow: UIColor(hex: 0xF2B705)
        }
    }

    var color: Color { Color(uiColor) }

    var title: LocalizedStringKey {
        switch self {
        case .black: "Black"
        case .blue: "Blue"
        case .red: "Red"
        case .yellow: "Yellow"
        }
    }
}

enum StrokeWidth: String, CaseIterable, Identifiable {
    case thin, medium, thick

    var id: Self { self }

    var points: CGFloat {
        switch self {
        case .thin: 3
        case .medium: 7
        case .thick: 13
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .thin: "Thin"
        case .medium: "Medium"
        case .thick: "Thick"
        }
    }
}

/// アプリ内の表示言語。SwiftUI の環境値 locale を差し替えて、その場で切り替える。
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case japanese = "ja"
    case english = "en"

    var id: Self { self }

    var locale: Locale {
        switch self {
        case .system:
            .autoupdatingCurrent
        case .japanese, .english:
            // 言語だけ差し替え、地域（日付の並びなど）は端末に合わせる
            Locale(languageCode: Locale.LanguageCode(rawValue), languageRegion: Locale.current.region)
        }
    }

    /// 言語名はその言語自身の表記で出す
    var title: Text {
        switch self {
        case .system: Text("Match Device")
        case .japanese: Text(verbatim: "日本語")
        case .english: Text(verbatim: "English")
        }
    }
}

/// 設定画面で選ぶ既定値（@AppStorage と共有するキー）
enum AppSettings {
    static let languageKey = "appLanguage"
    static let paperKey = "defaultPaper"
    static let penColorKey = "defaultPenColor"
    static let penWidthKey = "defaultPenWidth"

    static var paper: PaperStyle {
        UserDefaults.standard.string(forKey: paperKey).flatMap(PaperStyle.init) ?? .ruled
    }

    static var penColor: InkColor {
        UserDefaults.standard.string(forKey: penColorKey).flatMap(InkColor.init) ?? .black
    }

    static var penWidth: StrokeWidth {
        UserDefaults.standard.string(forKey: penWidthKey).flatMap(StrokeWidth.init) ?? .medium
    }
}
