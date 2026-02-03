import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int, String)
    case decodingError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from API."
        case .httpError(let code, let message): return "API error (\(code)): \(message)"
        case .decodingError(let message): return "Failed to parse response: \(message)"
        case .networkError(let message): return "Network error: \(message)"
        }
    }
}

// Response type for the structure-only call
struct TopicStructureResponse: Codable {
    let topicName: String
    let category: String?
    let subtopics: [String]
    let relatedTopics: [String]?
}

// Response type for the lesson-only call
struct LessonResponse: Codable {
    let lesson: LessonPayload
}

// Response type for the questions-only call
struct QuestionsResponse: Codable {
    let questions: [GeneratedQuestion]
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL = "https://kt-proxy.vercel.app/api/claude"
    private let model = "claude-haiku-4-5-20251001"
    private let systemPrompt = """
    You are a knowledgeable tutor who generates pedagogically sound, factually accurate quiz questions \
    and educational content. Adjust cognitive complexity to the specified difficulty level (1=beginner \
    recall, 5=expert analysis). Always respond in the specified JSON format. correctAnswer and every \
    entry in acceptableAnswers must be plain text: no parentheses, hyphens, colons, semicolons, or \
    special characters. Provide multiple acceptable answer phrasings to enable local answer checking.
    """

    private init() {}

    // MARK: - Generate Topic Structure (fast, ~500 tokens)

    func generateTopicStructure(topic: String) async throws -> (TopicStructure, [String], String) {
        let prompt = """
        The user wants to learn about: "\(topic)"

        Return a JSON object with ONLY this structure:
        {
          "topicName": "cleaned/normalized topic name",
          "category": "one of: History, Science, Geography, Arts & Culture, Sports, Entertainment, Technology, Nature, Language, People, Other",
          "subtopics": ["subtopic1", "subtopic2", ...],
          "relatedTopics": ["related topic 1", "related topic 2", "related topic 3"]
        }

        Subtopic strategy — choose the right approach:

        COLLECTION/LIST topics (user wants to learn about a set of items):
        - "Mountains of the World" → major ranges: "The Himalayas", "The Andes", "The Alps", etc.
        - "US Presidents" → eras: "Founding Era", "Civil War Era", etc.
        - "Countries of Europe" → regions: "Western Europe", "Scandinavia", etc.
        - Generate 8-15 subtopics at ONE consistent grouping level. Never mix levels.

        CONCEPTUAL topics (user wants to understand a subject):
        - "Machine Learning" → concepts: "Linear Regression", "Neural Networks", etc.
        - Generate 5-8 subtopics ordered foundational to advanced.

        Requirements:
        - relatedTopics: 3-5 broader topics to explore next (different from subtopics)
        - Return ONLY the JSON object, no other text
        """

        let response = try await makeRequest(prompt: prompt, maxTokens: 1024)
        let parsed = try decodeJSON(TopicStructureResponse.self, from: response)
        let structure = TopicStructure(name: parsed.topicName, subtopics: parsed.subtopics)
        return (structure, parsed.relatedTopics ?? [], parsed.category ?? "Other")
    }

    // MARK: - Generate Initial Lesson (parallel call, ~1000 tokens)

    func generateInitialLesson(topic: String, subtopic: String, depth: LearningDepth = .standard) async throws -> LessonPayload {
        let prompt = """
        Create a lesson about the subtopic "\(subtopic)" within the topic "\(topic)".

        Return a JSON object with ONLY this structure:
        {
          "lesson": {
            "subtopic": "\(subtopic)",
            "overview": "\(depth.overviewSentences) sentence overview rich with specific names, dates, and examples.",
            "keyFacts": ["Detailed fact 1", "Detailed fact 2", ...],
            "connections": ["Short Topic Name 1", "Short Topic Name 2"]
          }
        }

        Requirements:
        - Overview: \(depth.overviewSentences) sentences packed with specific details: names, dates, places, numbers. Never vague.
        - keyFacts: \(depth.keyFactsCount) detailed facts. Each MUST include specific names, dates, numbers, or concrete examples.
        - If the subtopic contains enumerable items (e.g., lakes, planets, states), ALL items must be listed.
        - connections: 2-3 short topic names (2-4 words each), NOT full sentences
        - Return ONLY the JSON object
        """

        let response = try await makeRequest(prompt: prompt, maxTokens: 2048)
        let parsed = try decodeJSON(LessonResponse.self, from: response)
        return parsed.lesson
    }

    // MARK: - Generate Initial Questions (parallel call, ~2000 tokens)

    func generateInitialQuestions(topic: String, subtopic: String, keyFacts: [String] = [], depth: LearningDepth = .standard) async throws -> [GeneratedQuestion] {
        let factsContext: String
        if !keyFacts.isEmpty {
            let factsList = keyFacts.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            factsContext = """

            The lesson taught these key facts — base your questions on them:
            \(factsList)

            """
        } else {
            factsContext = ""
        }

        let prompt = """
        Generate 10 quiz questions about "\(topic)", ALL about the subtopic "\(subtopic)" only.
        \(factsContext)
        Return a JSON object with ONLY this structure:
        {
          "questions": [
            {
              "questionText": "Question text?",
              "correctAnswer": "the correct answer",
              "acceptableAnswers": ["variation 1", "variation 2"],
              "choices": ["correct", "wrong 1", "wrong 2", "wrong 3"],
              "explanation": "2-4 sentence explanation",
              "subtopic": "\(subtopic)",
              "difficulty": \(depth.difficultyInt)
            }
          ]
        }

        Requirements:
        - Exactly 10 questions at difficulty \(depth.difficultyInt): \(depth.difficultyDescription)
        - Order questions from easier recall to harder application within the batch
        - About 6 multiple choice, 4 free-response

        Multiple choice rules:
        - "choices" with exactly 4 options; correctAnswer must exactly match one choice
        - Distractors MUST target common misconceptions or confusions, not random wrong answers
        - All 4 options must be similar in length, grammatical structure, and specificity
        - Never use absolutes ("always", "never") in only some options
        - Never use "all of the above" or "none of the above"
        - Vary the position of the correct answer across questions (not always first or last)
        - The question stem should be answerable before reading the options
        - Never embed a false premise or incorrect assumption in the stem (e.g. don't imply a causal relationship that doesn't exist)
        - Use MC for distinctions, comparisons, and conceptual understanding

        Free-response rules:
        - Set "choices" to null
        - Only ask for short unambiguous answers: a name, date, number, place, or term (1-5 words)
        - Use precise question stems: "Name the...", "What year...", "In which country..."
        - Never embed a false premise or incorrect assumption in the stem
        - Never require an answer that contains special characters, hyphens, or punctuation
        - correctAnswer = simplest common phrasing (e.g. "Everest" not "Mount Everest")

        acceptableAnswers (3-5 per question):
        - Include abbreviations, alternate spellings, and common short forms
        - Numeric answers: include both digit and written forms ("7" and "seven")
        - All entries: lowercase plain text, no articles ("the", "a"), no punctuation

        Explanation structure (2-4 sentences):
        1. State the correct answer and why it is correct
        2. If a distractor reflects a real misconception, explain why it's wrong. Do NOT invent a misconception that doesn't match the distractors — for factual/numeric recall, add useful context instead.
        3. Optional: a memory hook, mnemonic, or broader topic connection

        - Return ONLY the JSON object
        """

        let response = try await makeRequest(prompt: prompt, maxTokens: 3072)
        let parsed = try decodeJSON(QuestionsResponse.self, from: response)
        return parsed.questions
    }

    // MARK: - Generate Topic and First Batch (structure → lesson → questions)

    func generateTopicAndFirstBatch(topic: String, depth: LearningDepth = .standard) async throws -> (TopicStructure, [GeneratedQuestion], LessonPayload?, [String], String) {
        // Call 1: Get structure first (fastest)
        let (structure, relatedTopics, category) = try await generateTopicStructure(topic: topic)

        let firstSubtopic = structure.subtopics.first ?? structure.name

        // Call 2: Generate lesson
        let lesson = try? await generateInitialLesson(topic: structure.name, subtopic: firstSubtopic, depth: depth)

        // Call 3: Generate questions, seeded with lesson key facts
        let questions = (try? await generateInitialQuestions(topic: structure.name, subtopic: firstSubtopic, keyFacts: lesson?.keyFacts ?? [], depth: depth)) ?? []

        return (structure, questions, lesson, relatedTopics, category)
    }

    // MARK: - Generate Question Batch

    func generateQuestionBatch(
        topic: String,
        subtopics: [String],
        difficulty: Int,
        previousQuestions: [String],
        focusSubtopic: String? = nil,
        nextSubtopic: String? = nil,
        depth: LearningDepth = .standard
    ) async throws -> ([GeneratedQuestion], LessonPayload?) {
        let subtopicList = subtopics.joined(separator: ", ")
        let previousList = previousQuestions.map { "- \($0)" }.joined(separator: "\n")

        let focusInstruction: String
        if let focus = focusSubtopic {
            focusInstruction = "ALL 10 questions MUST be about the subtopic \"\(focus)\" only. Do NOT include questions about any other subtopic."
        } else {
            focusInstruction = "Spread across the listed subtopics."
        }

        let lessonInstruction: String
        if let next = nextSubtopic {
            lessonInstruction = """
            Also include a "nextLesson" field to teach the upcoming subtopic "\(next)":
            "nextLesson": {
              "subtopic": "\(next)",
              "overview": "\(depth.overviewSentences) sentence overview rich with specific names, dates, and examples. Not vague — include the who, what, when, and why.",
              "keyFacts": ["Detailed fact with specific names, dates, numbers", ...],
              "connections": ["Short Topic Name 1", "Short Topic Name 2"]
            }
            The overview must be \(depth.overviewSentences) sentences packed with specific details: names, dates, places, numbers, concrete examples. Never vague.
            Each keyFact (\(depth.keyFactsCount) total) MUST include specific names, dates, numbers, or concrete examples. No vague generalizations like "early versions were simple". Instead: "The Wright Model B (1910) was the first aircraft purchased by the US military, costing $25,000".
            IMPORTANT: If the subtopic contains enumerable items (e.g., specific lakes, planets, states), ALL items must be listed. Depth controls verbosity, never completeness.
            If the subtopic is a specific item (a mountain, a president, a country, etc.), the lesson should comprehensively cover that item: key stats, history, notable facts, and what makes it significant.
            connections: 2-3 short topic names (2-4 words each) like "Radar Technology" or "Aerial Tactics", NOT full sentences
            """
        } else {
            lessonInstruction = "Set \"nextLesson\" to null."
        }

        let prompt = """
        Generate 10 quiz questions about "\(topic)".

        Available subtopics: \(subtopicList)
        Difficulty level: \(difficulty) (1=beginner, 5=expert)
        \(focusInstruction)

        If the subtopics are specific items (e.g., specific mountains, specific presidents, specific countries), then questions should ask about concrete facts, stats, and details of those specific items. For example, for a subtopic "Himalayas": "What is the height of Mount Everest?", "Which country contains the most Himalayan peaks over 8,000m?", etc.

        Previously asked questions (DO NOT repeat these):
        \(previousList)

        Return a JSON object with this exact structure:
        {
          "questions": [
            {
              "questionText": "Multiple choice question?",
              "correctAnswer": "the correct option",
              "acceptableAnswers": ["variation 1"],
              "choices": ["the correct option", "wrong 1", "wrong 2", "wrong 3"],
              "explanation": "2-4 sentence teaching explanation",
              "subtopic": "which subtopic",
              "difficulty": \(difficulty)
            },
            {
              "questionText": "Free response question?",
              "correctAnswer": "short answer",
              "acceptableAnswers": ["variation 1", "variation 2"],
              "choices": null,
              "explanation": "2-4 sentence teaching explanation",
              "subtopic": "which subtopic",
              "difficulty": \(difficulty)
            }
          ],
          "nextLesson": null
        }

        \(lessonInstruction)

        Requirements:
        - Exactly 10 questions
        - Difficulty \(difficulty): \(depth.difficultyDescription)
        - Order questions from easier recall to harder application within the batch
        - Do not repeat any previously asked question
        - About 6 multiple choice, 4 free-response

        Multiple choice rules:
        - "choices" with exactly 4 options; correctAnswer must exactly match one choice
        - Distractors MUST target common misconceptions or confusions, not random wrong answers
        - All 4 options must be similar in length, grammatical structure, and specificity
        - Never use absolutes ("always", "never") in only some options
        - Never use "all of the above" or "none of the above"
        - Vary the position of the correct answer across questions (not always first or last)
        - The question stem should be answerable before reading the options
        - Never embed a false premise or incorrect assumption in the stem (e.g. don't imply a causal relationship that doesn't exist)
        - Use MC for distinctions, comparisons, and conceptual understanding

        Free-response rules:
        - Set "choices" to null
        - Only ask for short unambiguous answers: a name, date, number, place, or term (1-5 words)
        - Use precise question stems: "Name the...", "What year...", "In which country..."
        - Never embed a false premise or incorrect assumption in the stem
        - Never require an answer that contains special characters, hyphens, or punctuation
        - correctAnswer = simplest common phrasing (e.g. "Everest" not "Mount Everest")

        acceptableAnswers (3-5 per question):
        - Include abbreviations, alternate spellings, and common short forms
        - Numeric answers: include both digit and written forms ("7" and "seven")
        - All entries: lowercase plain text, no articles ("the", "a"), no punctuation

        Explanation structure (2-4 sentences):
        1. State the correct answer and why it is correct
        2. If a distractor reflects a real misconception, explain why it's wrong. Do NOT invent a misconception that doesn't match the distractors — for factual/numeric recall, add useful context instead.
        3. Optional: a memory hook, mnemonic, or broader topic connection

        - Return ONLY the JSON object
        """

        let response = try await makeRequest(prompt: prompt)
        let parsed = try decodeJSON(QuestionBatchResponse.self, from: response)
        return (parsed.questions, parsed.nextLesson)
    }

    // MARK: - Evaluate Uncertain Response

    func evaluateUncertainResponse(
        userAnswer: String,
        correctAnswer: String,
        questionContext: String
    ) async throws -> Bool {
        let prompt = """
        A student was asked: "\(questionContext)"
        The correct answer is: "\(correctAnswer)"
        The student answered: "\(userAnswer)"

        Is the student's answer correct or essentially correct (captures the key concept)?
        Return ONLY a JSON object: {"correct": true} or {"correct": false}
        """

        let response = try await makeRequest(prompt: prompt)
        let parsed = try decodeJSON(EvaluationResponse.self, from: response)
        return parsed.correct
    }

    // MARK: - Generate Deep Dive

    func generateDeepDive(topic: String) async throws -> DeepDiveContent {
        let prompt = """
        Create a comprehensive study brief about: "\(topic)"

        Return a JSON object with this exact structure:
        {
          "overview": "2-3 sentence summary of the topic",
          "keyConcepts": [
            "Essential fact or concept 1",
            "Essential fact or concept 2"
          ],
          "commonMisconceptions": [
            "Misconception 1: explanation of what people get wrong",
            "Misconception 2: explanation"
          ],
          "connections": ["Related Topic 1", "Related Topic 2", "Related Topic 3"]
        }

        Requirements:
        - Overview: 2-3 concise but informative sentences
        - Key Concepts: 8-12 essential facts, definitions, or ideas
        - Common Misconceptions: 2-3 things people often get wrong, with brief corrections
        - Connections: 3-5 related topic names the user might explore next
        - Return ONLY the JSON object
        """

        let response = try await makeRequest(prompt: prompt)
        return try decodeJSON(DeepDiveContent.self, from: response)
    }

    // MARK: - Private Helpers

    private func makeRequest(prompt: String, maxTokens: Int = 4096, retryCount: Int = 1) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body = ClaudeAPIRequest(
            model: model,
            max_tokens: maxTokens,
            system: systemPrompt,
            messages: [ClaudeMessage(role: "user", content: prompt)]
        )

        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                if retryCount > 0 {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    return try await makeRequest(prompt: prompt, maxTokens: maxTokens, retryCount: retryCount - 1)
                }
                throw APIError.httpError(httpResponse.statusCode, errorBody)
            }

            let apiResponse = try JSONDecoder().decode(ClaudeAPIResponse.self, from: data)

            guard let text = apiResponse.content.first?.text else {
                throw APIError.invalidResponse
            }

            return text
        } catch let error as APIError {
            throw error
        } catch {
            if retryCount > 0 {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                return try await makeRequest(prompt: prompt, maxTokens: maxTokens, retryCount: retryCount - 1)
            }
            throw APIError.networkError(error.localizedDescription)
        }
    }

    private func decodeJSON<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw APIError.decodingError("Failed to convert response to data")
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

}
