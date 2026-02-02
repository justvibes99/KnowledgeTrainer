import SwiftUI

struct DeepDiveView: View {
    let deepDive: DeepDive
    let onTopicTap: (String) -> Void

    private var sections: [(title: String, content: String)] {
        var result: [(String, String)] = []
        let parts = deepDive.content.components(separatedBy: "## ")

        for part in parts where !part.isEmpty {
            let lines = part.components(separatedBy: "\n")
            let title = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let content = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !title.isEmpty {
                result.append((title, content))
            }
        }

        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrutalCard(backgroundColor: .white) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(deepDive.topic)
                        .font(.system(.title2, design: .default, weight: .semibold))
                        .foregroundColor(.brutalBlack)

                    Text(deepDive.dateCreated.relativeDisplay)
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.flatSecondaryText)

                    ForEach(sections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.title)
                                .font(.system(.caption, design: .default, weight: .medium))
                                .foregroundColor(.brutalCoral)

                            Text(section.content)
                                .font(.system(.body, design: .default))
                                .foregroundColor(.brutalBlack)
                        }
                    }

                    if !deepDive.connectedTopics.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Explore Next")
                                .font(.system(.caption, design: .default, weight: .medium))
                                .foregroundColor(.brutalCoral)

                            FlowLayout(spacing: 8) {
                                ForEach(deepDive.connectedTopics, id: \.self) { topic in
                                    BrutalChip(title: topic, color: .brutalMint) {
                                        onTopicTap(topic)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
