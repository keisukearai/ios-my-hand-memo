//
//  NoteCard.swift
//  MyHandMemo
//

import SwiftUI
import UIKit

struct NoteCard: View {
    let note: Note

    @Environment(\.locale) private var locale

    /// アプリ内で選んだ言語の書式にするため、端末の locale ではなく環境値を使う
    private var dateText: String {
        note.updatedAt.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).locale(locale))
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay { thumbnail }
                .overlay(alignment: .topTrailing) {
                    if note.isPinned {
                        pinBadge
                    }
                }
                .clipped()
            Rectangle()
                .fill(Theme.cardDivider)
                .frame(height: 1)
            Text(verbatim: dateText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.inkSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 7, leading: 10, bottom: 9, trailing: 10))
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Theme.separator))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Note, \(dateText)"))
        .accessibilityValue(note.isPinned ? Text("Pinned") : Text(verbatim: ""))
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = note.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            PaperBackground(style: note.paper, pitch: 16)
        }
    }

    private var pinBadge: some View {
        Image(systemName: "pin.fill")
            .font(.system(size: 10))
            .foregroundStyle(Theme.accent)
            .frame(width: 20, height: 20)
            .background(Theme.accent.opacity(0.10), in: Circle())
            .padding(8)
    }
}

/// 「画像として共有」用
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
