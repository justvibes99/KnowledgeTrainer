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
                Text("SAVED LIBRARY")
                    .font(.system(.caption, design: .default, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.brutalBlack)

                TextField("Filter...", text: $filterText)
                    .font(.system(.caption, design: .default))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.brutalBlack, lineWidth: 2)
                    )

                ForEach(deepDives) { deepDive in
                    HStack(spacing: 0) {
                        Button(action: { onSelect(deepDive) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(deepDive.topic.uppercased())
                                        .font(.system(.caption, design: .default, weight: .bold))
                                        .tracking(0.8)
                                        .foregroundColor(.brutalBlack)
                                        .lineLimit(1)
                                    Text(deepDive.dateCreated.relativeDisplay)
                                        .font(.system(.caption2, design: .default))
                                        .foregroundColor(.brutalBlack.opacity(0.6))
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
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.brutalBlack, lineWidth: 2)
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
