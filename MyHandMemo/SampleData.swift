//
//  SampleData.swift
//  MyHandMemo
//
//  App Store 用スクリーンショットのための見本データ。
//  起動引数 -seedSampleData を付けたときだけ入る。DEBUG ビルドにしか含めない。
//

#if DEBUG

import PencilKit
import SwiftData
import SwiftUI
import UIKit

enum SampleData {
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-seedSampleData")
    }

    /// 同じ絵を何度でも作れるように、乱数は種から起こす
    private struct Seeded: RandomNumberGenerator {
        private var state: UInt64
        init(_ seed: UInt64) { state = seed &* 6_364_136_223_846_793_005 &+ 1 }
        mutating func next() -> UInt64 {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return state
        }
    }

    static func seedIfRequested(into context: ModelContext) {
        guard isRequested else { return }
        let existing = (try? context.fetchCount(FetchDescriptor<Note>())) ?? 0
        guard existing == 0 else { return }

        // 画面幅に合わせて描くと、キャンバスでも一覧でも収まりがよくなる
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let screenWidth = scene?.screen.bounds.width ?? 0
        let w = screenWidth > 0 ? screenWidth : NoteRenderer.defaultCanvasSize.width
        let now = Date.now

        for (index, spec) in specs.enumerated() {
            var rng = Seeded(spec.seed)
            let drawing = spec.build(w, &rng)

            let note = Note(paper: spec.paper)
            note.drawingData = drawing.dataRepresentation()
            note.canvasWidth = Double(w)
            note.canvasHeight = Double(NoteRenderer.defaultCanvasSize.height)
            note.isPinned = spec.pinned
            // 一覧の並びが毎回同じになるように日付をずらす
            note.updatedAt = now.addingTimeInterval(-Double(index) * 86_400 * 1.7)
            note.createdAt = note.updatedAt
            note.thumbnailData = NoteRenderer
                .thumbnail(drawing: drawing, paper: spec.paper, canvasWidth: w)
                .pngData()
            context.insert(note)
        }
        try? context.save()
    }

    // MARK: - 見本の中身

    private struct Spec {
        let seed: UInt64
        let paper: PaperStyle
        let pinned: Bool
        let build: (CGFloat, inout Seeded) -> PKDrawing
    }

    private static let specs: [Spec] = [
        Spec(seed: 11, paper: .ruled, pinned: true) { w, rng in
            // 買い物メモ風。見出しの走り書きと、点つきの箇条書き
            var strokes = handwrittenLine(y: 96, x: 40, width: w * 0.46,
                                          ink: .blue, weight: 6.5, &rng)
            strokes += underline(y: 126, x: 40, width: w * 0.46, ink: .blue)
            for (i, ratio) in [0.62, 0.50, 0.68, 0.44].enumerated() {
                let y = 188.0 + Double(i) * 62
                strokes += bullet(at: CGPoint(x: 46, y: y - 6), ink: .black)
                strokes += handwrittenLine(y: y, x: 72, width: w * ratio,
                                           ink: .black, weight: 5, &rng)
            }
            return PKDrawing(strokes: strokes)
        },
        Spec(seed: 27, paper: .plain, pinned: false) { w, rng in
            // アイデアメモ風。大きめの走り書きを丸で囲む
            var strokes = handwrittenLine(y: 150, x: 52, width: w * 0.58,
                                          ink: .black, weight: 7, &rng)
            strokes += handwrittenLine(y: 206, x: 52, width: w * 0.40,
                                       ink: .black, weight: 7, &rng)
            strokes += circle(center: CGPoint(x: w * 0.5, y: 178),
                              radius: CGSize(width: w * 0.40, height: 96),
                              ink: .red, weight: 5.5, &rng)
            return PKDrawing(strokes: strokes)
        },
        Spec(seed: 43, paper: .ruled, pinned: false) { w, rng in
            // 伝言メモ風。マーカーで一行だけ目立たせる
            var strokes = handwrittenLine(y: 104, x: 40, width: w * 0.66,
                                          ink: .black, weight: 5.5, &rng)
            strokes += marker(y: 160, x: 38, width: w * 0.54)
            strokes += handwrittenLine(y: 160, x: 44, width: w * 0.50,
                                       ink: .black, weight: 5.5, &rng)
            strokes += handwrittenLine(y: 222, x: 40, width: w * 0.38,
                                       ink: .black, weight: 5.5, &rng)
            return PKDrawing(strokes: strokes)
        },
        Spec(seed: 59, paper: .grid, pinned: false) { w, rng in
            // 図のメモ風。四角と矢印
            var strokes = box(rect: CGRect(x: 56, y: 110, width: w * 0.32, height: 84),
                              ink: .black, &rng)
            strokes += arrow(from: CGPoint(x: 56 + w * 0.32 + 14, y: 152),
                             to: CGPoint(x: w - 66, y: 152), ink: .blue, &rng)
            strokes += handwrittenLine(y: 236, x: 56, width: w * 0.56,
                                       ink: .black, weight: 5, &rng)
            return PKDrawing(strokes: strokes)
        },
        Spec(seed: 71, paper: .plain, pinned: false) { w, rng in
            // 走り書きだけのメモ。青のペンで数行
            var strokes: [PKStroke] = []
            for (i, ratio) in [0.70, 0.62, 0.74, 0.40].enumerated() {
                strokes += handwrittenLine(y: 120 + Double(i) * 54, x: 44, width: w * ratio,
                                           ink: .blue, weight: 6, &rng)
            }
            return PKDrawing(strokes: strokes)
        },
        Spec(seed: 89, paper: .ruled, pinned: false) { w, rng in
            // 大事なところを赤で囲んだメモ
            var strokes = handwrittenLine(y: 108, x: 42, width: w * 0.50,
                                          ink: .black, weight: 5.5, &rng)
            strokes += handwrittenLine(y: 170, x: 42, width: w * 0.64,
                                       ink: .black, weight: 5.5, &rng)
            strokes += box(rect: CGRect(x: 36, y: 196, width: w * 0.44, height: 46),
                           ink: .red, &rng)
            strokes += handwrittenLine(y: 228, x: 50, width: w * 0.34,
                                       ink: .red, weight: 5.5, &rng)
            return PKDrawing(strokes: strokes)
        },
    ]

    // MARK: - 筆を組み立てる部品

    private static func ink(_ color: InkColor, _ type: PKInk.InkType = .pen) -> PKInk {
        PKInk(type, color: color.uiColor)
    }

    private static func stroke(_ points: [CGPoint], ink: PKInk, weight: CGFloat) -> PKStroke {
        let pts = points.enumerated().map { i, p in
            PKStrokePoint(location: p,
                          timeOffset: Double(i) * 0.008,
                          size: CGSize(width: weight, height: weight),
                          opacity: 1,
                          force: 1,
                          azimuth: 0,
                          altitude: .pi / 2)
        }
        return PKStroke(ink: ink, path: PKStrokePath(controlPoints: pts, creationDate: Date()))
    }

    /// 字の代わりに、山・谷・輪・縦棒をつなげた「単語」を並べる。
    /// 一定の波にすると機械的に見えるので、字の形を1文字ずつ選んでつなぐ。
    private enum Glyph: CaseIterable {
        case hump      // n のような山
        case valley    // u のような谷
        case loop      // e のような輪
        case tall      // l のような縦に伸びる棒
        case descend   // g のように下へ抜ける
    }

    private static func glyphPoints(_ glyph: Glyph, at origin: CGPoint, width: CGFloat,
                                    xHeight: CGFloat) -> [CGPoint] {
        let steps = 14
        return (0...steps).map { i -> CGPoint in
            let t = CGFloat(i) / CGFloat(steps)
            let px = origin.x + width * t
            let py: CGFloat
            switch glyph {
            case .hump:
                py = origin.y - sin(t * .pi) * xHeight
            case .valley:
                py = origin.y - xHeight + sin(t * .pi) * xHeight
            case .loop:
                py = origin.y - sin(t * .pi) * xHeight * 0.75
                    - sin(t * 2 * .pi) * xHeight * 0.2
            case .tall:
                py = origin.y - sin(t * .pi) * xHeight * 1.75
            case .descend:
                py = origin.y - sin(t * .pi) * xHeight * 0.7
                    + max(0, t - 0.6) * xHeight * 1.4
            }
            return CGPoint(x: px, y: py)
        }
    }

    private static func handwrittenLine(y: CGFloat, x: CGFloat, width: CGFloat,
                                        ink color: InkColor, weight: CGFloat,
                                        _ rng: inout Seeded) -> [PKStroke] {
        var strokes: [PKStroke] = []
        var cursor = x
        let end = x + width
        while cursor < end - 14 {
            // 1単語 = 2〜5文字ぶんを一筆でつなぐ
            let letters = Int.random(in: 2...5, using: &rng)
            var points: [CGPoint] = []
            var pen = CGPoint(x: cursor, y: y)
            for _ in 0..<letters {
                let lw = CGFloat.random(in: 8...13, using: &rng)
                if pen.x + lw > end { break }
                let xHeight = CGFloat.random(in: 9...13, using: &rng)
                let glyph = Glyph.allCases.randomElement(using: &rng) ?? .hump
                let seg = glyphPoints(glyph, at: pen, width: lw, xHeight: xHeight)
                points += points.isEmpty ? seg : Array(seg.dropFirst())
                pen = CGPoint(x: pen.x + lw, y: y + CGFloat.random(in: -1...1, using: &rng))
            }
            guard points.count > 2 else { break }
            strokes.append(stroke(points, ink: ink(color), weight: weight))
            cursor = pen.x + CGFloat.random(in: 8...14, using: &rng)
        }
        return strokes
    }

    private static func underline(y: CGFloat, x: CGFloat, width: CGFloat,
                                  ink color: InkColor) -> [PKStroke] {
        let points = stride(from: 0.0, through: 1.0, by: 0.05).map { t -> CGPoint in
            CGPoint(x: x + width * CGFloat(t), y: y + sin(CGFloat(t) * .pi) * 2.5)
        }
        return [stroke(points, ink: ink(color), weight: 4)]
    }

    private static func bullet(at center: CGPoint, ink color: InkColor) -> [PKStroke] {
        let points = stride(from: 0.0, through: 1.0, by: 0.08).map { t -> CGPoint in
            let a = CGFloat(t) * 2 * .pi
            return CGPoint(x: center.x + cos(a) * 3.5, y: center.y + sin(a) * 3.5)
        }
        return [stroke(points, ink: ink(color), weight: 5)]
    }

    private static func circle(center: CGPoint, radius: CGSize, ink color: InkColor,
                               weight: CGFloat, _ rng: inout Seeded) -> [PKStroke] {
        let wobble = CGFloat.random(in: 2...4, using: &rng)
        let points = stride(from: 0.0, through: 1.06, by: 0.02).map { t -> CGPoint in
            let a = CGFloat(t) * 2 * .pi - .pi / 2
            let r = 1 + sin(a * 3) * wobble / 100
            return CGPoint(x: center.x + cos(a) * radius.width / 2 * r,
                           y: center.y + sin(a) * radius.height / 2 * r)
        }
        return [stroke(points, ink: ink(color), weight: weight)]
    }

    private static func marker(y: CGFloat, x: CGFloat, width: CGFloat) -> [PKStroke] {
        let points = stride(from: 0.0, through: 1.0, by: 0.05).map { t -> CGPoint in
            CGPoint(x: x + width * CGFloat(t), y: y - 2)
        }
        return [stroke(points, ink: ink(.yellow, .marker), weight: 26)]
    }

    private static func box(rect: CGRect, ink color: InkColor,
                            _ rng: inout Seeded) -> [PKStroke] {
        // 角をわずかにずらして手描きらしくする。inout は閉包に渡せないので先に引いておく
        var j: [CGFloat] = []
        for _ in 0..<8 { j.append(CGFloat.random(in: -2.5...2.5, using: &rng)) }
        let corners = [
            CGPoint(x: rect.minX + j[0], y: rect.minY + j[1]),
            CGPoint(x: rect.maxX + j[2], y: rect.minY + j[3]),
            CGPoint(x: rect.maxX + j[4], y: rect.maxY + j[5]),
            CGPoint(x: rect.minX + j[6], y: rect.maxY + j[7]),
        ]
        var points: [CGPoint] = []
        for i in 0...4 {
            let a = corners[i % 4], b = corners[(i + 1) % 4]
            for s in stride(from: 0.0, through: 1.0, by: 0.1) {
                points.append(CGPoint(x: a.x + (b.x - a.x) * CGFloat(s),
                                      y: a.y + (b.y - a.y) * CGFloat(s)))
            }
            if i == 3 { break }
        }
        return [stroke(points, ink: ink(color), weight: 5)]
    }

    private static func arrow(from: CGPoint, to: CGPoint, ink color: InkColor,
                              _ rng: inout Seeded) -> [PKStroke] {
        let sag = CGFloat.random(in: 3...7, using: &rng)
        let shaft = stride(from: 0.0, through: 1.0, by: 0.05).map { t -> CGPoint in
            CGPoint(x: from.x + (to.x - from.x) * CGFloat(t),
                    y: from.y + (to.y - from.y) * CGFloat(t) + sin(CGFloat(t) * .pi) * sag)
        }
        let head = [
            CGPoint(x: to.x - 14, y: to.y - 10),
            CGPoint(x: to.x, y: to.y),
            CGPoint(x: to.x - 14, y: to.y + 10),
        ]
        return [stroke(shaft, ink: ink(color), weight: 5),
                stroke(head, ink: ink(color), weight: 5)]
    }
}

#endif
