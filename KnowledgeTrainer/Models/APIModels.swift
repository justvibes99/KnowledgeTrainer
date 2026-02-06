import Foundation

// MARK: - OpenAI API Request/Response

struct OpenAIAPIRequest: Codable {
    let model: String
    let max_tokens: Int
    let messages: [OpenAIMessage]
    let response_format: ResponseFormat?
    let temperature: Double?

    struct ResponseFormat: Codable {
        let type: String
    }
}

struct OpenAIMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIAPIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIResponseMessage
    let finish_reason: String?
}

struct OpenAIResponseMessage: Codable {
    let content: String?
}

// MARK: - Lesson Payload

struct LessonPayload: Codable {
    let subtopic: String
    let overview: String
    let keyFacts: [String]
    let misconceptions: [String]?
    let connections: [String]?
}

// MARK: - Topic Generation Response

struct TopicGenerationResponse: Codable {
    let topicName: String
    let subtopics: [String]
    let questions: [GeneratedQuestion]
    let initialLesson: LessonPayload?
    let relatedTopics: [String]?
    let category: String?
}

struct GeneratedQuestion: Codable, Identifiable {
    let questionText: String
    let correctAnswer: String
    let acceptableAnswers: [String]
    let explanation: String
    let subtopic: String
    let difficulty: Int
    let choices: [String]?

    var id: String { questionText }

    var isMultipleChoice: Bool { choices != nil && !(choices?.isEmpty ?? true) }

    /// Validates and repairs MC questions. Ensures correctAnswer matches a choice exactly,
    /// there are exactly 4 distinct choices, and repairs case mismatches instead of discarding.
    var validated: GeneratedQuestion? {
        guard let choices = choices, !choices.isEmpty else { return self }
        // Require exactly 4 distinct choices
        let uniqueChoices = Set(choices.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
        guard choices.count == 4, uniqueChoices.count == 4 else { return nil }

        let normalizedCorrect = correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let matchingChoice = choices.first(where: {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedCorrect
        }) else { return nil }

        // Repair: use the exact choice string as correctAnswer if it differs
        if matchingChoice == correctAnswer { return self }
        return GeneratedQuestion(
            questionText: questionText,
            correctAnswer: matchingChoice,
            acceptableAnswers: acceptableAnswers,
            explanation: explanation,
            subtopic: subtopic,
            difficulty: difficulty,
            choices: choices
        )
    }

    static func validateBatch(_ questions: [GeneratedQuestion]) -> [GeneratedQuestion] {
        questions.compactMap { $0.validated }
    }
}

// MARK: - Question Batch Response

struct QuestionBatchResponse: Codable {
    let questions: [GeneratedQuestion]
    let nextLesson: LessonPayload?
}

// MARK: - Uncertain Evaluation Response

struct EvaluationResponse: Codable {
    let correct: Bool
}

// MARK: - Deep Dive Response

struct DeepDiveContent: Codable {
    let overview: String
    let keyConcepts: [String]
    let commonMisconceptions: [String]
    let connections: [String]
}

// MARK: - Topic Structure (used internally)

struct TopicStructure {
    let name: String
    let subtopics: [String]
}
