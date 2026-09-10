//
//  NoteRenderer.swift
//  MyHandMemo
//

import PencilKit
import SwiftUI
import UIKit

/// 用紙（無地・罫線・方眼）の表示
struct PaperBackground: View {
    let style: PaperStyle
    var pitch: CGFloat = Theme.paperPitch

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.surface))
            for rect in style.lineRects(in: size, pitch: pitch) {
                context.fill(Path(rect), with: .color(Theme.paperLine))
            }
        }
    }
}

/// 描画を用紙ごと画像にする（サムネイルと共有用）
enum NoteRenderer {
    static let defaultCanvasSize = CGSize(width: 393, height: 659)

    /// 上部4:3の切り出し。縮小で全体を入れると走り書きが潰れるため、書き始めの上部を使う。
    static func thumbnail(drawing: PKDrawing, paper: PaperStyle, canvasWidth: CGFloat) -> UIImage {
        let crop = CGRect(x: 0, y: 0, width: canvasWidth, height: canvasWidth * 3 / 4)
        return render(drawing: drawing, paper: paper, rect: crop, targetWidth: 174, scale: 3)
    }

    static func shareImage(for note: Note) -> UIImage {
        let drawing = (try? PKDrawing(data: note.drawingData)) ?? PKDrawing()
        var size = CGSize(width: note.canvasWidth, height: note.canvasHeight)
        if size.width <= 0 || size.height <= 0 {
            size = defaultCanvasSize
        }
        return render(drawing: drawing, paper: note.paper, rect: CGRect(origin: .zero, size: size),
                      targetWidth: size.width, scale: 3)
    }

    private static func render(drawing: PKDrawing, paper: PaperStyle, rect: CGRect,
                               targetWidth: CGFloat, scale: CGFloat) -> UIImage {
        let factor = targetWidth / rect.width
        let size = CGSize(width: targetWidth, height: rect.height * factor)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        var strokes = UIImage()
        // ダーク環境の色変換を避けるため、ライトの見た目で書き出す
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            strokes = drawing.image(from: rect, scale: scale * factor)
        }

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cg = context.cgContext
            Theme.surfaceUI.setFill()
            cg.fill(CGRect(origin: .zero, size: size))

            cg.saveGState()
            cg.scaleBy(x: factor, y: factor)
            cg.translateBy(x: -rect.minX, y: -rect.minY)
            Theme.paperLineUI.setFill()
            let paperSize = CGSize(width: rect.maxX, height: rect.maxY)
            for line in paper.lineRects(in: paperSize, pitch: Theme.paperPitch) {
                cg.fill(line)
            }
            cg.restoreGState()

            strokes.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
