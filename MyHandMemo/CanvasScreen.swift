//
//  CanvasScreen.swift
//  MyHandMemo
//

import PencilKit
import SwiftData
import SwiftUI

enum DrawingTool {
    case pen, marker, eraser
}

/// 書く画面（上バー44 / キャンバス / 下ツールバー56）
struct CanvasScreen: View {
    let note: Note

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var controller = CanvasController()
    @State private var tool: DrawingTool = .pen
    @State private var pen: InkSettings
    @State private var marker = InkSettings(color: .yellow, width: .thick)
    @State private var showStylePopover = false
    @State private var showClearToast = false
    @State private var toastTask: Task<Void, Never>?
    @State private var saveTask: Task<Void, Never>?
    @State private var isDirty = false

    init(note: Note) {
        self.note = note
        _pen = State(initialValue: InkSettings(color: AppSettings.penColor, width: AppSettings.penWidth))
    }

    /// ポップオーバーで編集する対象。消しゴム中はペンの設定を見せる。
    private var activeInk: Binding<InkSettings> {
        tool == .marker ? $marker : $pen
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ZStack(alignment: .bottom) {
                PaperBackground(style: note.paper)
                PencilCanvas(controller: controller)
                if showStylePopover {
                    StylePopover(ink: activeInk)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
                }
                if showClearToast {
                    clearToast
                }
            }
            .clipped()
            toolBar
        }
        .background(Theme.surface)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .onAppear(perform: setUp)
        .onDisappear(perform: finish)
        .onChange(of: tool) { applyTool() }
        .onChange(of: pen) {
            if tool == .eraser { tool = .pen }
            applyTool()
        }
        .onChange(of: marker) { applyTool() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                saveIfNeeded()
                try? context.save()
            }
        }
    }

    // MARK: Bars

    private var topBar: some View {
        HStack(spacing: 0) {
            barButton("chevron.left", label: "Back", weight: .semibold, color: Theme.accent) {
                dismiss()
            }
            Spacer()
            barButton("arrow.uturn.backward", label: "Undo",
                      color: controller.canUndo ? Theme.accent : Theme.disabled) {
                hideToast()
                controller.undo()
            }
            .disabled(!controller.canUndo)
            barButton("arrow.uturn.forward", label: "Redo",
                      color: controller.canRedo ? Theme.accent : Theme.disabled) {
                hideToast()
                controller.redo()
            }
            .disabled(!controller.canRedo)
        }
        .padding(.horizontal, 8)
        .frame(height: 44)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.separator).frame(height: 1)
        }
    }

    private var toolBar: some View {
        HStack(spacing: 0) {
            toolButton(.pen, symbol: "pencil.tip", label: "Pen")
            Spacer()
            toolButton(.marker, symbol: "highlighter", label: "Marker")
            Spacer()
            toolButton(.eraser, symbol: "eraser", label: "Eraser")
            Spacer()
            swatchButton
            Spacer()
            moreMenu
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(Theme.background.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(Theme.separator).frame(height: 1)
        }
    }

    private func barButton(_ symbol: String, label: LocalizedStringKey, weight: Font.Weight = .regular,
                           color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: weight))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
    }

    private func toolButton(_ target: DrawingTool, symbol: String, label: LocalizedStringKey) -> some View {
        let isSelected = tool == target
        return Button {
            tool = target
            showStylePopover = false
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 21))
                .foregroundStyle(isSelected ? Theme.accent : Theme.ink)
                .frame(width: 44, height: 44)
                .background(isSelected ? Theme.accentFill : .clear, in: RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 現在の色を、現在の太さに応じた大きさの円で表示する
    private var swatchButton: some View {
        let ink = activeInk.wrappedValue
        let diameter: CGFloat = switch ink.width {
        case .thin: 16
        case .medium: 21
        case .thick: 26
        }
        return Button {
            withAnimation(.snappy(duration: 0.2)) { showStylePopover.toggle() }
        } label: {
            ZStack {
                Circle()
                    .fill(showStylePopover ? Theme.accent : Theme.disabled)
                    .frame(width: diameter + 3, height: diameter + 3)
                Circle()
                    .fill(Theme.surface)
                    .frame(width: diameter, height: diameter)
                Circle()
                    .fill(ink.color.color)
                    .frame(width: diameter - 4, height: diameter - 4)
            }
            .frame(width: 44, height: 44)
            .background(showStylePopover ? Theme.accentFill : .clear, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Color & Width"))
    }

    /// 1メモに1回以下しか触らない「用紙」と「全消去」はここに畳む
    private var moreMenu: some View {
        Menu {
            Section("Paper") {
                ForEach(PaperStyle.allCases) { style in
                    Button {
                        changePaper(to: style)
                    } label: {
                        if note.paper == style {
                            Label(style.title, systemImage: "checkmark")
                        } else {
                            Text(style.title)
                        }
                    }
                }
            }
            Section {
                Button(role: .destructive, action: clearAll) {
                    Label("Clear All", systemImage: "trash")
                }
                .disabled(controller.isEmpty)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(Text("More"))
    }

    /// 全消去は確認せず、左下に5秒だけ「元に戻す」を出す（右下の鉛筆ボタンと重ならない位置）
    private var clearToast: some View {
        HStack(spacing: 16) {
            Text("Cleared")
                .foregroundStyle(Theme.surface.opacity(0.85))
            Button("Undo") {
                hideToast()
                controller.undo()
            }
            .fontWeight(.semibold)
            .foregroundStyle(Theme.surface)
        }
        .font(.system(size: 15))
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 12))
        .padding(.leading, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: Actions

    private func setUp() {
        let drawing = (try? PKDrawing(data: note.drawingData)) ?? PKDrawing()
        controller.load(drawing)
        controller.onDrawingChange = { drawingDidChange() }
        controller.onBeginStroke = {
            if showStylePopover {
                withAnimation(.snappy(duration: 0.2)) { showStylePopover = false }
            }
            // トーストの「元に戻す」が全消去以外を戻さないよう、書き始めたら閉じる
            hideToast()
        }
        applyTool()    }

    private func applyTool() {
        switch tool {
        case .pen:
            controller.setTool(inkingTool(.pen, pen))
        case .marker:
            controller.setTool(inkingTool(.marker, marker))
        case .eraser:
            controller.setTool(PKEraserTool(.bitmap))
        }
    }

    private func inkingTool(_ type: PKInkingTool.InkType, _ ink: InkSettings) -> PKInkingTool {
        let range = type.validWidthRange
        let width = min(max(ink.width.points, range.lowerBound), range.upperBound)
        return PKInkingTool(type, color: ink.color.uiColor, width: width)
    }

    private func changePaper(to style: PaperStyle) {
        guard note.paper != style else { return }
        note.paper = style
        isDirty = true
        saveIfNeeded()
    }

    private func clearAll() {
        showStylePopover = false
        controller.clear()
        withAnimation(.snappy) { showClearToast = true }
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            withAnimation(.snappy) { showClearToast = false }
        }
    }

    private func hideToast() {
        toastTask?.cancel()
        guard showClearToast else { return }
        withAnimation(.snappy) { showClearToast = false }
    }

    private func drawingDidChange() {
        isDirty = true
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            saveIfNeeded()
        }
    }

    private func saveIfNeeded() {
        saveTask?.cancel()
        guard isDirty else { return }
        let drawing = controller.canvasView.drawing
        // 新規メモは最初の1画を書くまで保存しない（空のメモを一覧に出さないため）
        if note.modelContext == nil {
            guard !drawing.strokes.isEmpty else { return }
            context.insert(note)
        }
        isDirty = false

        var size = controller.canvasView.bounds.size
        if size.width <= 0 || size.height <= 0 {
            size = NoteRenderer.defaultCanvasSize
        }
        note.drawingData = drawing.dataRepresentation()
        note.canvasWidth = size.width
        note.canvasHeight = size.height
        note.updatedAt = .now
        note.thumbnailData = NoteRenderer.thumbnail(drawing: drawing, paper: note.paper,
                                                    canvasWidth: size.width).pngData()
    }

    private func finish() {
        saveTask?.cancel()
        toastTask?.cancel()
        if controller.canvasView.drawing.strokes.isEmpty {
            if note.modelContext != nil {
                context.delete(note)
            }
        } else {
            saveIfNeeded()
        }
        try? context.save()
    }
}
