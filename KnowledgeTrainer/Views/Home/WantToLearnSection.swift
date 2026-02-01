import SwiftUI

struct WantToLearnSection: View {
    let items: [WantToLearnItem]
    let onStart: (WantToLearnItem) -> Void
    let onRemove: (WantToLearnItem) -> Void

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("WANT TO LEARN")
                    .font(.system(.caption, design: .default, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.brutalBlack)

                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Button(action: { onStart(item) }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.topicName.uppercased())
                                        .font(.system(.caption, design: .default, weight: .bold))
                                        .tracking(0.8)
                                        .foregroundColor(.brutalBlack)
                                        .lineLimit(1)

                                    if let source = item.sourceSubtopic {
                                        Text("from \(source)")
                                            .font(.system(.caption2, design: .default))
                                            .foregroundColor(.brutalBlack.opacity(0.5))
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.caption.bold())
                                    .foregroundColor(.brutalBlack)
                            }
                        }
                        .buttonStyle(.plain)

                        Button(action: { onRemove(item) }) {
                            Image(systemName: "xmark")
                                .font(.caption2.bold())
                                .foregroundColor(.brutalBlack.opacity(0.4))
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.brutalYellow.opacity(0.3))
                    .overlay(
                        Rectangle()
                            .stroke(Color.brutalBlack, lineWidth: 2)
                    )
                }
            }
        }
    }
}
