//
//  PencilCanvas.swift
//  MyHandMemo
//

import PencilKit
import SwiftUI

/// ウィンドウ共有の UndoManager を使うと他の画面の操作と混ざるため、メモごとに専用の UndoManager を持たせる。
final class NoteCanvasView: PKCanvasView {
    private let noteUndoManager = UndoManager()

    override var undoManager: UndoManager? { noteUndoManager }
}

@Observable
final class CanvasController: NSObject, PKCanvasViewDelegate {
    @ObservationIgnored let canvasView = NoteCanvasView()
    @ObservationIgnored var onDrawingChange: (() -> Void)?
    @ObservationIgnored var onBeginStroke: (() -> Void)?

    private(set) var canUndo = false
    private(set) var canRedo = false
    private(set) var isEmpty = true

    override init() {
        super.init()
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.overrideUserInterfaceStyle = .light
        canvasView.isScrollEnabled = false
        canvasView.contentInsetAdjustmentBehavior = .never

        let names: [Notification.Name] = [
            .NSUndoManagerDidCloseUndoGroup,
            .NSUndoManagerDidUndoChange,
            .NSUndoManagerDidRedoChange,
        ]
        for name in names {
            NotificationCenter.default.addObserver(
                self, selector: #selector(undoStateDidChange),
                name: name, object: canvasView.undoManager
            )
        }
    }

    /// 既存の描画を読み込む。読み込み自体は「元に戻す」の対象にしない。
    func load(_ drawing: PKDrawing) {
        canvasView.delegate = nil
        canvasView.drawing = drawing
        canvasView.undoManager?.removeAllActions()
        canvasView.delegate = self
        refreshState()
    }

    func setTool(_ tool: PKTool) {
        canvasView.tool = tool
    }

    func undo() { canvasView.undoManager?.undo() }
    func redo() { canvasView.undoManager?.redo() }

    /// 全消去。上バーの「元に戻す」とトーストの両方から戻せるよう UndoManager に積む。
    func clear() {
        replaceDrawing(with: PKDrawing())
    }

    private func replaceDrawing(with drawing: PKDrawing) {
        let previous = canvasView.drawing
        canvasView.drawing = drawing
        canvasView.undoManager?.registerUndo(withTarget: self) { controller in
            controller.replaceDrawing(with: previous)
        }
        refreshState()
    }

    private func refreshState() {
        canUndo = canvasView.undoManager?.canUndo ?? false
        canRedo = canvasView.undoManager?.canRedo ?? false
        isEmpty = canvasView.drawing.strokes.isEmpty
    }

    @objc private func undoStateDidChange(_ notification: Notification) {
        refreshState()
    }

    // MARK: PKCanvasViewDelegate

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        refreshState()
        onDrawingChange?()
    }

    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {
        onBeginStroke?()
    }
}

struct PencilCanvas: UIViewRepresentable {
    let controller: CanvasController

    func makeUIView(context: Context) -> PKCanvasView {
        controller.canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
