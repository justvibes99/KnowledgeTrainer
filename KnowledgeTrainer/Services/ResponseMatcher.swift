import Foundation

enum MatchResult {
    case correct
    case incorrect
    case uncertain
}

struct ResponseMatcher {
    static func evaluate(userAnswer: String, acceptableAnswers: [String], correctAnswer: String) -> MatchResult {
        let cleaned = normalize(userAnswer)

        if cleaned.isEmpty || cleaned.count < 2 {
            for acceptable in acceptableAnswers {
                if normalize(acceptable) == cleaned {
                    return .correct
                }
            }
            return .incorrect
        }

        let allAcceptable = ([correctAnswer] + acceptableAnswers).map { normalize($0) }

        // Exact match
        for acceptable in allAcceptable {
            if cleaned == acceptable {
                return .correct
            }
        }

        // Contains match (user answer contains acceptable or vice versa)
        for acceptable in allAcceptable {
            if cleaned.contains(acceptable) || acceptable.contains(cleaned) {
                return .correct
            }
        }

        // Levenshtein distance <= 2
        for acceptable in allAcceptable {
            if levenshteinDistance(cleaned, acceptable) <= 2 {
                return .correct
            }
        }

        // Word overlap check
        let userWords = Set(cleaned.split(separator: " ").map { String($0) })
        for acceptable in allAcceptable {
            let acceptableWords = Set(acceptable.split(separator: " ").map { String($0) })
            if acceptableWords.isEmpty { continue }
            let overlap = userWords.intersection(acceptableWords)
            let overlapRatio = Double(overlap.count) / Double(acceptableWords.count)
            if overlapRatio >= 0.5 {
                return .uncertain
            }
        }

        return .incorrect
    }

    // MARK: - Normalization

    private static func normalize(_ text: String) -> String {
        var result = text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let articles = ["the ", "a ", "an "]
        for article in articles {
            if result.hasPrefix(article) {
                result = String(result.dropFirst(article.count))
            }
        }

        result = result
            .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        return result
    }

    // MARK: - Levenshtein Distance

    static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }

        return matrix[m][n]
    }
}
