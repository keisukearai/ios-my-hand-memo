//
//  HomeView.swift
//  MyHandMemo
//

import SwiftData
import SwiftUI

enum AppRoute: Hashable {
    case settings
    case language
}

struct HomeView: View {
    private struct SharedImage: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    @Environment(\.modelContext) private var context
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var path = NavigationPath()
    @State private var noteToDelete: Note?
    @State private var sharedImage: SharedImage?

    /// ピン留めを先頭に、それぞれ更新日時の新しい順
    private var sortedNotes: [Note] {
        notes.filter(\.isPinned) + notes.filter { !$0.isPinned }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if notes.isEmpty {
                    emptyState
                } else {
                    grid
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background.ignoresSafeArea())
            .overlay(alignment: .bottomTrailing) { newNoteButton }
            // タイトルはナビバー内に左寄せで出す。標準タイトルは表示だけ消し、戻るボタンの文言用に残す。
            #if DEBUG
            .task { SampleData.seedIfRequested(into: context) }
            #endif
            .navigationTitle("Handwritten Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(removing: .title)
            .toolbar {
                if #available(iOS 26.0, *) {
                    titleItem
                        .sharedBackgroundVisibility(.hidden)
                } else {
                    titleItem
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: AppRoute.settings) {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(Text("Settings"))
                }
            }
            .navigationDestination(for: Note.self) { note in
                CanvasScreen(note: note)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .settings: SettingsView()
                case .language: LanguageSettingsView()
                }
            }
            .confirmationDialog(
                "This note will be deleted. This can't be undone.",
                isPresented: Binding(
                    get: { noteToDelete != nil },
                    set: { if !$0 { noteToDelete = nil } }
                ),
                titleVisibility: .visible,
                presenting: noteToDelete
            ) { note in
                Button("Delete", role: .destructive) {
                    context.delete(note)
                    try? context.save()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(item: $sharedImage) { shared in
                ActivityView(items: [shared.image])
                    .presentationDetents([.medium, .large])
                    .ignoresSafeArea()
            }
        }
    }

    private var titleItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Text("Handwritten Notes")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.ink)
                .fixedSize()
                .accessibilityAddTraits(.isHeader)
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(sortedNotes) { note in
                    NavigationLink(value: note) {
                        NoteCard(note: note)
                    }
                    .buttonStyle(.plain)
                    .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 12))
                    .contextMenu { menu(for: note) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            // 右下の鉛筆ボタンに最後の行が隠れないように
            .padding(.bottom, 96)
        }
    }

    @ViewBuilder
    private func menu(for note: Note) -> some View {
        Section {
            Button {
                note.isPinned.toggle()
                try? context.save()
            } label: {
                if note.isPinned {
                    Label("Unpin", systemImage: "pin.slash.fill")
                } else {
                    Label("Pin", systemImage: "pin.fill")
                }
            }
            Button {
                context.insert(note.duplicated())
                try? context.save()
            } label: {
                Label("Duplicate", systemImage: "square.on.square")
            }
            Button {
                sharedImage = SharedImage(image: NoteRenderer.shareImage(for: note))
            } label: {
                Label("Share as Image", systemImage: "square.and.arrow.up")
            }
        }
        Section {
            // メモそのものの削除は戻し先がないので確認する
            Button(role: .destructive) {
                noteToDelete = note
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 26) {
            ScribbleShape()
                .stroke(Theme.emptyIllustration,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .frame(width: 220, height: 150)
                .accessibilityHidden(true)
            Text("Tap the pencil to start writing")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    /// 位置と大きさは一覧・空状態で同一。空のときだけ鉛筆アイコンにする。
    private var newNoteButton: some View {
        Button(action: createNote) {
            Image(systemName: notes.isEmpty ? "pencil" : "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Theme.accent, in: Circle())
                .shadow(color: Theme.ink.opacity(0.22), radius: 8, y: 6)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
        .accessibilityLabel(Text("New Note"))
    }

    /// 最初の1画を書いた時点で保存される（CanvasScreen 側で insert する）
    private func createNote() {
        path.append(Note(paper: AppSettings.paper))
    }
}

/// 空状態の走り書き風イラスト（SF Symbols ではなく描画）
private struct ScribbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 220
        let sy = rect.height / 150
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var path = Path()
        path.move(to: p(28, 96))
        path.addCurve(to: p(72, 40), control1: p(42, 56), control2: p(58, 38))
        path.addCurve(to: p(92, 86), control1: p(86, 42), control2: p(78, 84))
        path.addCurve(to: p(128, 52), control1: p(106, 88), control2: p(114, 52))
        path.addCurve(to: p(152, 78), control1: p(140, 52), control2: p(140, 78))
        path.addCurve(to: p(176, 52), control1: p(162, 78), control2: p(170, 66))
        path.move(to: p(46, 122))
        path.addCurve(to: p(174, 120), control1: p(86, 130), control2: p(130, 130))
        return path
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Note.self, inMemory: true)
}
