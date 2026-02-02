import Foundation

enum APIError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse
    case httpError(Int, String)
    case decodingError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key found. Please add your Anthropic API key in Settings."
        case .invalidResponse: return "Invalid response from API."
        case .httpError(let code, let message): return "API error (\(code)): \(message)"
        case .decodingError(let message): return "Failed to parse response: \(message)"
        case .networkError(let message): return "Network error: \(message)"
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-haiku-4-5-20251001"
    private let systemPrompt = """
    You are a knowledgeable tutor. Generate factually accurate questions and educational content. \
    Adjust complexity to the specified difficulty level (1=beginner, 5=expert). Always respond in the \
    specified JSON format. For each question, provide multiple acceptable answer phrasings to enable \
    local answer checking.
    """

    private init() {}

    // MARK: - Generate Topic and First Batch

    func generateTopicAndFirstBatch(topic: String, depth: LearningDepth = .standard) async throws -> (TopicStructure, [GeneratedQuestion], LessonPayload?, [String], String) {
        let prompt = """
        The user wants to learn about: "\(topic)"

        Return a JSON object with this exact structure:
        {
          "topicName": "cleaned/normalized topic name",
          "category": "one of: History, Science, Geography, Arts & Culture, Sports, Entertainment, Technology, Nature, Language, People, Other",
          "subtopics": ["subtopic1", "subtopic2", ...],
          "relatedTopics": ["related topic 1", "related topic 2", "related topic 3"],
          "initialLesson": {
            "subtopic": "the first subtopic name",
            "overview": "\(depth.overviewSentences) sentence overview rich with specific names, dates, and examples. Not vague — include the who, what, when, and why.",
            "keyFacts": ["Detailed fact with specific names, dates, numbers", "Another specific fact", ...],
            "connections": ["Short Topic Name 1", "Short Topic Name 2"]
          },
          "questions": [
            {
              "questionText": "Multiple choice question?",
              "correctAnswer": "the correct option text",
              "acceptableAnswers": ["variation 1"],
              "choices": ["the correct option text", "plausible wrong 1", "plausible wrong 2", "plausible wrong 3"],
              "explanation": "2-4 sentence teaching explanation",
              "subtopic": "which subtopic",
              "difficulty": \(depth.difficultyInt)
            },
            {
              "questionText": "Free response question?",
              "correctAnswer": "the answer",
              "acceptableAnswers": ["variation 1", "variation 2", "variation 3"],
              "choices": null,
              "explanation": "2-4 sentence teaching explanation",
              "subtopic": "which subtopic",
              "difficulty": \(depth.difficultyInt)
            }
          ]
        }

        CRITICAL — Subtopic strategy (choose the right approach for the topic):

        Some topics are COLLECTION/LIST topics where the user wants to learn about a set of specific items. Examples:
        - "Mountains of the World" → subtopics should be major mountain RANGES: "The Himalayas", "The Andes", "The Alps", "The Rocky Mountains", "The Karakoram Range", "The Atlas Mountains", etc. Individual peaks (Everest, K2, Kilimanjaro) are covered WITHIN their range's lesson, NOT as separate subtopics.
        - "US Presidents" → subtopics should be eras or small groups: "Founding Era (Washington–Adams)", "Civil War Era (Lincoln–Johnson)", etc.
        - "Countries of Europe" → subtopics should be regional groups: "Western Europe", "Scandinavia", "Eastern Europe", etc.
        - "Dog Breeds" → subtopics should be breed groups: "Herding Dogs", "Sporting Dogs", "Terriers", etc.
        - "Chemical Elements" → subtopics should be element groups: "Alkali Metals", "Noble Gases", "Transition Metals", etc.
        - "World War II Battles" → subtopics should be theaters/campaigns: "European Western Front", "Pacific Theater", "Eastern Front", etc.
        - "Classical Composers" → subtopics should be periods: "Baroque Period", "Classical Period", "Romantic Period", etc.

        CRITICAL: Pick ONE consistent level of grouping for subtopics. Never mix grouping levels (e.g., don't have both "The Himalayas" and "Mount Everest" as separate subtopics — Everest belongs inside the Himalayas lesson). Individual items are covered in detail within their group's lesson and quiz questions.

        Other topics are CONCEPTUAL topics where the user wants to understand a subject in depth. Examples:
        - "Machine Learning" → subtopics should be concepts: "Linear Regression", "Neural Networks", "Decision Trees", etc.
        - "Music Theory" → subtopics should be concepts: "Scales and Keys", "Chord Progressions", "Time Signatures", etc.
        - "Photography" → subtopics should be skills/concepts: "Exposure Triangle", "Composition Rules", "Lighting", etc.

        For COLLECTION topics:
        - Generate 8-15 subtopics at a consistent grouping level. Do NOT mix individual items with groups.
        - Each subtopic is a natural grouping. The lesson and quiz for that subtopic teach about all the important items within that group.
        - Questions should ask about specific facts, stats, and details of items within each group (e.g., for "The Himalayas": "What is the height of Mount Everest?", "Which country contains the most Himalayan peaks over 8,000m?")

        For CONCEPTUAL topics:
        - Generate 5-8 subtopics ordered from foundational to advanced

        Requirements:
        - Generate exactly 10 questions ALL about the FIRST subtopic only. Do NOT include questions about any other subtopic.
        - All questions should be at difficulty level \(depth.difficultyInt): \(depth.difficultyDescription)
        - Each question should have 3-5 acceptable answer variations (synonyms, different phrasings, abbreviations)
        - Explanations should be educational, 2-4 sentences with memory hooks
        - Question types: mix of multiple choice and free-response. About 6 should be multiple choice and 4 should be free-response (type-in).
        - For multiple choice questions: include a "choices" array with exactly 4 options (one correct, three plausible wrong answers). Shuffle the correct answer position randomly. The correctAnswer must exactly match one of the choices.
        - For free-response questions: set "choices" to null. These work best for short factual answers (names, dates, numbers).
        - The initialLesson overview should be \(depth.overviewSentences) sentences packed with specific details: names, dates, places, numbers, and concrete examples. Never write vague summaries.
        - The initialLesson keyFacts should contain \(depth.keyFactsCount) detailed facts. Each fact MUST include specific names, dates, numbers, or concrete examples. For example, instead of "Early bombers were converted aircraft", write "The Italian Caproni Ca.1 (1914) was among the first purpose-designed bombers, carrying up to 450kg of bombs". No vague generalizations.
        - IMPORTANT: If the topic contains enumerable items (e.g., the Great Lakes, planets in the solar system, US states in a region), ALL items must be included in the lesson regardless of depth level. Depth controls verbosity and question complexity, never completeness of coverage.
        - The initialLesson connections should be 2-3 short topic names (2-4 words each) like "Engine Development" or "Navigation Systems", NOT full sentences
        - relatedTopics: 3-5 broader topic names the user might want to explore next (different from subtopics)
        - Return ONLY the JSON object, no other text
        """

        let response = try await makeRequest(prompt: prompt)
        let parsed = try decodeJSON(TopicGenerationResponse.self, from: response)

        let structure = TopicStructure(name: parsed.topicName, subtopics: parsed.subtopics)
        return (structure, parsed.questions, parsed.initialLesson, parsed.relatedTopics ?? [], parsed.category ?? "Other")
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
        - Questions should progress from easier recall to harder application within the batch
        - 3-5 acceptable answer variations per question
        - Do not repeat any previously asked question
        - Question types: mix of multiple choice and free-response. About 6 should be multiple choice and 4 should be free-response.
        - For multiple choice: include "choices" with exactly 4 options (one correct, three plausible wrong). Shuffle correct answer position. correctAnswer must exactly match one choice.
        - For free-response: set "choices" to null. Best for short factual answers (names, dates, numbers).
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

    // MARK: - Test Connection

    func testConnection() async throws -> Bool {
        let prompt = "Return exactly: {\"status\": \"ok\"}"
        let _ = try await makeRequest(prompt: prompt, maxTokens: 50)
        return true
    }

    // MARK: - Private Helpers

    private func makeRequest(prompt: String, maxTokens: Int = 4096, retryCount: Int = 1) async throws -> String {
        guard let apiKey = KeychainManager.retrieve() else {
            throw APIError.noAPIKey
        }

        guard let url = URL(string: baseURL) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

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
