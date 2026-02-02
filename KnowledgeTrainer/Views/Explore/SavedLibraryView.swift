import SwiftUI

struct SavedLibraryView: View {
    let deepDives: [DeepDive]
    @Binding var filterText: String
    let onSelect: (DeepDive) -> Void
    let onDelete: (DeepDive) -> Void

    @State private var itemToDelete: DeepDive?

    var body: some View {
        if !deepDives.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Saved Library")
                    .font(.system(.caption, design: .default, weight: .medium))
                    .foregroundColor(.brutalBlack)

                TextField("Filter...", text: $filterText)
                    .font(.system(.caption, design: .default))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.flatSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.flatBorder, lineWidth: 1)
                    )

                ForEach(deepDives) { deepDive in
                    HStack(spacing: 0) {
                        Button(action: { onSelect(deepDive) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(deepDive.topic)
                                        .font(.system(.caption, design: .default, weight: .medium))
                                        .foregroundColor(.brutalBlack)
                                        .lineLimit(1)
                                    Text(deepDive.dateCreated.relativeDisplay)
                                        .font(.system(.caption2, design: .default))
                                        .foregroundColor(.flatSecondaryText)
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Button(action: { itemToDelete = deepDive }) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.brutalCoral)
                                .padding(8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.flatSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.flatBorder, lineWidth: 1)
                    )
                }
            }
            .alert("Delete Deep Dive?", isPresented: Binding(
                get: { itemToDelete != nil },
                set: { if !$0 { itemToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        onDelete(item)
                        itemToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) { itemToDelete = nil }
            } message: {
                Text("This deep dive will be permanently deleted.")
            }
        }
    }
}
