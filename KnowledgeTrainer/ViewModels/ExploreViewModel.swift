import Foundation
import SwiftData

@Observable
final class ExploreViewModel {
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    var currentDeepDive: DeepDive?
    var filterText: String = ""

    func generateDeepDive(modelContext: ModelContext) async {
        let input = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let content = try await APIClient.shared.generateDeepDive(topic: input)

            let contentString = formatDeepDiveContent(content)
            let deepDive = DeepDive(
                topic: input,
                content: contentString,
                connectedTopics: content.connections,
                dateCreated: Date()
            )

            modelContext.insert(deepDive)
            try modelContext.save()

            currentDeepDive = deepDive
            searchText = ""
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = false
    }

    func filteredDeepDives(_ deepDives: [DeepDive]) -> [DeepDive] {
        if filterText.isEmpty {
            return deepDives.sorted { $0.dateCreated > $1.dateCreated }
        }
        return deepDives
            .filter { $0.topic.localizedCaseInsensitiveContains(filterText) }
            .sorted { $0.dateCreated > $1.dateCreated }
    }

    func deleteDeepDive(_ deepDive: DeepDive, modelContext: ModelContext) {
        modelContext.delete(deepDive)
        try? modelContext.save()
    }

    private func formatDeepDiveContent(_ content: DeepDiveContent) -> String {
        var result = "## Overview\n\n\(content.overview)\n\n"
        result += "## Key Concepts\n\n"
        for concept in content.keyConcepts {
            result += "- \(concept)\n"
        }
        result += "\n## Common Misconceptions\n\n"
        for misconception in content.commonMisconceptions {
            result += "- \(misconception)\n"
        }
        return result
    }
}
