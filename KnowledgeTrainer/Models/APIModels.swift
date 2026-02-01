import Foundation

// MARK: - Claude API Request/Response

struct ClaudeAPIRequest: Codable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [ClaudeMessage]
}

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeAPIResponse: Codable {
    let content: [ClaudeContent]
}

struct ClaudeContent: Codable {
    let type: String
    let text: String?
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
