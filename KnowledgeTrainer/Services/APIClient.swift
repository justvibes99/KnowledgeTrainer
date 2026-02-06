import Foundation

enum APIError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int, String)
    case decodingError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Something went wrong. Please try again."
        case .httpError(let code, _):
            if code == 429 {
                return "Too many requests. Please wait a moment and try again."
            } else if code >= 500 {
                return "The server is having trouble. Please try again later."
            }
            return "Something went wrong. Please try again."
        case .decodingError:
            return "We received an unexpected response. Please try again."
        case .networkError:
            return "Couldn't connect. Check your internet and try again."
        }
    }

    var technicalDescription: String {
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

    private let baseURL = "https://kt-proxy.vercel.app/api/openai"
    private let model = "gpt-4.1-mini"
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 120
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }()
    private let systemPrompt = """
    You are a knowledgeable tutor who generates pedagogically sound, factually accurate quiz questions \
    and educational content. Adjust cognitive complexity to the specified difficulty level. \
    Always respond with valid JSON matching the requested schema. \
    If you are not confident about a specific fact, date, or number, use well-established widely-known \
    facts instead of guessing. Never fabricate statistics, dates, or attributions. \
    Only include facts that would appear in a standard encyclopedia or textbook. \
    Do not include statistics, rankings, or records that change frequently unless the question \
    explicitly asks about a well-established historical record. \
    correctAnswer and every entry in acceptableAnswers must be plain text: no parentheses, hyphens, \
    colons, semicolons, or special characters.
    """

    private init() {}

    // MARK: - Shared Question Rules

    private func questionRules(for depth: LearningDepth) -> String {
        let examples: String
        switch depth {
        case .casual:
            examples = """
            Example of a well-formed MC question (Remember level):
            {
              "questionText": "Which planet in our solar system has the most moons?",
              "correctAnswer": "Saturn",
              "acceptableAnswers": [],
              "choices": ["Jupiter", "Saturn", "Uranus", "Neptune"],
              "explanation": "Saturn has 146 confirmed moons as of 2024, surpassing Jupiter's 95. Many were discovered by the Cassini mission.",
              "subtopic": "Planets",
              "difficulty": 2
            }

            Example of a well-formed FR question (Remember level):
            {
              "questionText": "What year did the Wright Brothers make their first powered flight?",
              "correctAnswer": "1903",
              "acceptableAnswers": ["1903", "nineteen oh three", "nineteen hundred and three"],
              "choices": null,
              "explanation": "The Wright Brothers' first powered flight occurred on December 17, 1903, at Kitty Hawk, North Carolina. The flight lasted 12 seconds.",
              "subtopic": "Aviation History",
              "difficulty": 2
            }
            """
        case .standard:
            examples = """
            Example of a well-formed MC question (Apply level):
            {
              "questionText": "A coastal city is experiencing rapid population growth. Which geographic factor would most limit its expansion?",
              "correctAnswer": "Mountain range bordering the city",
              "acceptableAnswers": [],
              "choices": ["Mountain range bordering the city", "A river running through downtown", "Proximity to a national forest", "Being located in a seismic zone"],
              "explanation": "Mountains create a hard physical barrier to urban sprawl, forcing vertical growth or costly tunneling. Rivers and forests can be built around, and seismic zones slow but don't prevent expansion.",
              "subtopic": "Urban Geography",
              "difficulty": 3
            }

            Example of a well-formed FR question (Understand level):
            {
              "questionText": "What process causes tectonic plates to move apart at mid-ocean ridges?",
              "correctAnswer": "seafloor spreading",
              "acceptableAnswers": ["sea floor spreading", "ocean floor spreading", "divergence", "mantle convection"],
              "choices": null,
              "explanation": "Seafloor spreading occurs when magma rises at mid-ocean ridges, pushing plates apart. This was first proposed by Harry Hess in 1962 and confirmed by symmetric magnetic striping patterns on the ocean floor.",
              "subtopic": "Plate Tectonics",
              "difficulty": 3
            }
            """
        case .deep:
            examples = """
            Example of a well-formed MC question (Analyze level):
            {
              "questionText": "The Treaty of Westphalia (1648) established the principle of state sovereignty. Which modern development most directly challenges this principle?",
              "correctAnswer": "International criminal tribunals prosecuting heads of state",
              "acceptableAnswers": [],
              "choices": ["International criminal tribunals prosecuting heads of state", "The formation of military alliances like NATO", "Bilateral trade agreements between nations", "The establishment of the United Nations General Assembly"],
              "explanation": "International criminal tribunals like the ICC directly override state sovereignty by asserting jurisdiction over national leaders. Military alliances and trade agreements are voluntary, and the UN General Assembly has no binding authority over members.",
              "subtopic": "International Relations",
              "difficulty": 5
            }

            Example of a well-formed FR question (Evaluate level):
            {
              "questionText": "Name the logical fallacy in this argument: 'We should trust this diet plan because a famous actor endorses it.'",
              "correctAnswer": "appeal to authority",
              "acceptableAnswers": ["argument from authority", "false authority", "ad verecundiam", "celebrity endorsement fallacy"],
              "choices": null,
              "explanation": "This is an appeal to authority (argumentum ad verecundiam) because the actor's fame doesn't make them a nutrition expert. A valid authority appeal requires expertise relevant to the claim being made.",
              "subtopic": "Critical Thinking",
              "difficulty": 4
            }
            """
        }

        return """
        \(examples)

        Multiple choice rules:
        - "choices" with exactly 4 options
        - correctAnswer must be a CHARACTER-FOR-CHARACTER copy of one of the choices entries (same case, spacing, and wording)
        - Distractors MUST target common misconceptions or confusions, not random wrong answers
        - All 4 options must be similar in length, grammatical structure, and specificity
        - Never use absolutes ("always", "never") in only some options
        - Never use "all of the above" or "none of the above"
        - Vary the position of the correct answer across questions (not always first or last)
        - The question stem should be answerable before reading the options
        - Never embed a false premise or incorrect assumption in the stem
        - For multiple choice questions, set acceptableAnswers to an empty array []

        Free-response rules:
        - Set "choices" to null
        - Only ask for short unambiguous answers: a name, date, number, place, or term (1-5 words)
        - Use precise question stems: "Name the...", "What year...", "In which country..."
        - Never embed a false premise or incorrect assumption in the stem
        - Never require an answer that contains special characters, hyphens, or punctuation
        - correctAnswer = simplest common phrasing (e.g. "Everest" not "Mount Everest")
        - Every FR question must have exactly ONE factual answer verifiable in an encyclopedia
        - BAD: "What caused the French Revolution?" (too many valid answers)
        - GOOD: "In what year did the French Revolution begin?" (single answer: 1789)

        acceptableAnswers (3-5 per FR question, empty [] for MC):
        - Include abbreviations, alternate spellings, and common short forms
        - For answers containing abbreviations (St., Mt., Dr.), include both abbreviated and full-word forms
        - Numeric answers: include both digit and written forms ("7" and "seven")
        - All entries: lowercase plain text, no articles ("the", "a"), no punctuation

        Explanation structure (2-4 sentences):
        1. State the correct answer and why it is correct
        2. If a distractor reflects a real misconception, explain why it's wrong. For factual/numeric recall, add useful context instead.
        3. Optional: a memory hook, mnemonic, or broader topic connection
        """
    }

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
        // Ensure at least one subtopic (fallback to topic name)
        let subtopics = parsed.subtopics.isEmpty ? [parsed.topicName] : parsed.subtopics
        let structure = TopicStructure(name: parsed.topicName, subtopics: subtopics)
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
            "misconceptions": ["Common misconception and why it is wrong"],
            "connections": ["Short Topic Name 1", "Short Topic Name 2"]
          }
        }

        Requirements:
        - Overview: \(depth.overviewSentences) sentences packed with specific details: names, dates, places, numbers. Never vague.
        - keyFacts: \(depth.keyFactsCount) detailed facts. Each MUST include specific names, dates, numbers, or concrete examples.
        - For well-known finite sets (e.g., planets, Great Lakes, continents), list all items. For large or open-ended sets, list the most notable examples.
        - misconceptions: 1-3 things people commonly get wrong about this subtopic, with brief corrections
        - connections: 2-3 short topic names (2-4 words each), NOT full sentences
        - Return ONLY the JSON object
        """

        let response = try await makeRequest(prompt: prompt, maxTokens: 2048)
        let parsed = try decodeJSON(LessonResponse.self, from: response)
        return parsed.lesson
    }

    // MARK: - Generate Initial Questions (parallel call, ~2000 tokens)

    func generateInitialQuestions(topic: String, subtopic: String, keyFacts: [String] = [], misconceptions: [String] = [], depth: LearningDepth = .standard) async throws -> [GeneratedQuestion] {
        let factsContext: String
        if !keyFacts.isEmpty {
            let factsList = keyFacts.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            let misconceptionContext: String
            if !misconceptions.isEmpty {
                misconceptionContext = "\n\nCommon misconceptions to target with distractor choices:\n" + misconceptions.map { "- \($0)" }.joined(separator: "\n")
            } else {
                misconceptionContext = ""
            }
            factsContext = """

            The lesson taught these key facts. Every question MUST be answerable using ONLY the facts listed below. Do not ask about details not covered in these facts.
            \(factsList)\(misconceptionContext)

            """
        } else {
            factsContext = ""
        }

        let prompt = """
        Generate 10 quiz questions about "\(topic)", ALL about the subtopic "\(subtopic)" only.
        \(factsContext)
        Return a JSON object with this structure:
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
        - Exactly 10 questions. Difficulty range: \(depth.difficultyRange)
        - Style: \(depth.difficultyDescription)
        - Bloom's taxonomy allocation: \(depth.bloomsAllocation)
        - Each question must test a DIFFERENT concept, fact, or relationship — no two questions should ask about the same underlying idea even if worded differently
        - Exactly 6 multiple choice and exactly 4 free-response

        \(questionRules(for: depth))
        """

        let response = try await makeRequest(prompt: prompt, maxTokens: 4096, temperature: 0.5)
        let parsed = try decodeJSON(QuestionsResponse.self, from: response)
        return GeneratedQuestion.validateBatch(parsed.questions)
    }

    // MARK: - Generate Topic and First Batch (structure → lesson → questions)

    func generateTopicAndFirstBatch(topic: String, depth: LearningDepth = .standard) async throws -> (TopicStructure, [GeneratedQuestion], LessonPayload?, [String], String) {
        // Call 1: Get structure first (fastest)
        let (structure, relatedTopics, category) = try await generateTopicStructure(topic: topic)

        let firstSubtopic = structure.subtopics[0]

        // Call 2: Generate lesson (retry once on failure)
        var lesson = try? await generateInitialLesson(topic: structure.name, subtopic: firstSubtopic, depth: depth)
        if lesson == nil {
            lesson = try? await generateInitialLesson(topic: structure.name, subtopic: firstSubtopic, depth: depth)
        }

        // Call 3: Generate questions, seeded with lesson key facts and misconceptions
        let questions = (try? await generateInitialQuestions(topic: structure.name, subtopic: firstSubtopic, keyFacts: lesson?.keyFacts ?? [], misconceptions: lesson?.misconceptions ?? [], depth: depth)) ?? []

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
        depth: LearningDepth = .standard,
        keyFacts: [String] = [],
        misconceptions: [String] = [],
        previousSubtopicSummaries: [String] = []
    ) async throws -> ([GeneratedQuestion], LessonPayload?) {
        let subtopicList = subtopics.joined(separator: ", ")
        let recentQuestions = previousQuestions.suffix(30)
        let previousList = recentQuestions.map { "- \($0)" }.joined(separator: "\n")

        let focusInstruction: String
        if let focus = focusSubtopic {
            focusInstruction = "ALL 10 questions MUST be about the subtopic \"\(focus)\" only. Do NOT include questions about any other subtopic."
        } else {
            focusInstruction = "Spread across the listed subtopics."
        }

        let factsContext: String
        if !keyFacts.isEmpty {
            let factsList = keyFacts.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
            let misconceptionContext: String
            if !misconceptions.isEmpty {
                misconceptionContext = "\n\nCommon misconceptions to target with distractor choices:\n" + misconceptions.map { "- \($0)" }.joined(separator: "\n")
            } else {
                misconceptionContext = ""
            }
            factsContext = """

            The lesson taught these key facts. Every question MUST be answerable using ONLY the facts listed below. Do not ask about details not covered in these facts.
            \(factsList)\(misconceptionContext)

            """
        } else {
            factsContext = ""
        }

        let lessonInstruction: String
        if let next = nextSubtopic {
            let previousContext = previousSubtopicSummaries.isEmpty ? "" : """
            Previously covered subtopics (do NOT repeat this material in the new lesson):
            \(previousSubtopicSummaries.joined(separator: "\n"))

            """
            lessonInstruction = """
            Also include a "nextLesson" field to teach the upcoming subtopic "\(next)":
            "nextLesson": {
              "subtopic": "\(next)",
              "overview": "\(depth.overviewSentences) sentence overview rich with specific names, dates, and examples.",
              "keyFacts": ["Detailed fact with specific names, dates, numbers", ...],
              "misconceptions": ["Common misconception and why it is wrong"],
              "connections": ["Short Topic Name 1", "Short Topic Name 2"]
            }
            \(previousContext)The overview must be \(depth.overviewSentences) sentences packed with specific details: names, dates, places, numbers, concrete examples. Never vague.
            Each keyFact (\(depth.keyFactsCount) total) MUST include specific names, dates, numbers, or concrete examples.
            For well-known finite sets (e.g., planets, Great Lakes), list all items. For large or open-ended sets, list the most notable examples.
            If the subtopic is a specific item (a mountain, a president, a country, etc.), the lesson should comprehensively cover that item: key stats, history, notable facts, and what makes it significant.
            misconceptions: 1-3 things people commonly get wrong about this subtopic, with brief corrections
            connections: 2-3 short topic names (2-4 words each), NOT full sentences
            """
        } else {
            lessonInstruction = "Set \"nextLesson\" to null."
        }

        let prompt = """
        Generate 10 quiz questions about "\(topic)".

        Available subtopics: \(subtopicList)
        Difficulty level: \(difficulty) (1=beginner, 5=expert)
        \(focusInstruction)
        \(factsContext)
        If the subtopics are specific items (e.g., specific mountains, specific presidents, specific countries), then questions should ask about concrete facts, stats, and details of those specific items.

        Previously asked questions (DO NOT repeat these):
        \(previousList)

        Return a JSON object with this structure:
        {
          "questions": [
            {
              "questionText": "Question text?",
              "correctAnswer": "the correct answer",
              "acceptableAnswers": [],
              "choices": ["correct", "wrong 1", "wrong 2", "wrong 3"],
              "explanation": "2-4 sentence teaching explanation",
              "subtopic": "which subtopic",
              "difficulty": \(difficulty)
            }
          ],
          "nextLesson": null
        }

        \(lessonInstruction)

        Requirements:
        - Exactly 10 questions. Difficulty range: \(depth.difficultyRange)
        - Style: \(depth.difficultyDescription)
        - Bloom's taxonomy allocation: \(depth.bloomsAllocation)
        - Each question must test a DIFFERENT concept, fact, or relationship — no two questions should ask about the same underlying idea even if worded differently
        - Do not repeat any previously asked question
        - Exactly 6 multiple choice and exactly 4 free-response

        \(questionRules(for: depth))
        """

        let batchMaxTokens: Int
        if nextSubtopic != nil {
            batchMaxTokens = depth == .deep ? 6144 : 5120
        } else {
            batchMaxTokens = 4096
        }
        let response = try await makeRequest(prompt: prompt, maxTokens: batchMaxTokens, temperature: 0.5)
        let parsed = try decodeJSON(QuestionBatchResponse.self, from: response)
        return (GeneratedQuestion.validateBatch(parsed.questions), parsed.nextLesson)
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

        Is the student's answer factually equivalent to the correct answer?
        Accept: synonyms, abbreviations, minor misspellings, and alternate common names.
        Reject: broader/narrower terms, partial answers, or different facts.

        Examples:
        - Correct: "1776", Student: "1776 AD" → {"correct": true}
        - Correct: "Saturn", Student: "Jupiter" → {"correct": false}
        - Correct: "Photosynthesis", Student: "photo synthesis" → {"correct": true}
        - Correct: "Marie Curie", Student: "Curie" → {"correct": true}
        - Correct: "France", Student: "Europe" → {"correct": false}
        - Correct: "Mitochondria", Student: "The mitochondria" → {"correct": true}

        Return ONLY: {"correct": true} or {"correct": false}
        """

        let response = try await makeRequest(prompt: prompt, maxTokens: 64, temperature: 0.0)
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

        let response = try await makeRequest(prompt: prompt, maxTokens: 2048)
        return try decodeJSON(DeepDiveContent.self, from: response)
    }

    // MARK: - Private Helpers

    private func makeRequest(prompt: String, maxTokens: Int = 4096, temperature: Double = 0.3, retryCount: Int = 1) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body = OpenAIAPIRequest(
            model: model,
            max_tokens: maxTokens,
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: prompt)
            ],
            response_format: OpenAIAPIRequest.ResponseFormat(type: "json_object"),
            temperature: temperature
        )

        request.httpBody = try JSONEncoder().encode(body)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            if httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                let isRetryable = httpResponse.statusCode == 429 || httpResponse.statusCode >= 500
                if isRetryable && retryCount > 0 {
                    let delay: UInt64 = httpResponse.statusCode == 429 ? 2_000_000_000 : 1_000_000_000
                    try await Task.sleep(nanoseconds: delay)
                    return try await makeRequest(prompt: prompt, maxTokens: maxTokens, temperature: temperature, retryCount: retryCount - 1)
                }
                throw APIError.httpError(httpResponse.statusCode, errorBody)
            }

            // Proxy returns reassembled JSON (may have leading whitespace from keepalives)
            let trimmedData = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespaces)
                .data(using: .utf8) ?? data

            let apiResponse = try JSONDecoder().decode(OpenAIAPIResponse.self, from: trimmedData)

            // Detect truncation and retry with higher token budget
            if apiResponse.choices.first?.finish_reason == "length" && retryCount > 0 {
                return try await makeRequest(prompt: prompt, maxTokens: maxTokens + 2048, temperature: temperature, retryCount: retryCount - 1)
            }

            guard let text = apiResponse.choices.first?.message.content else {
                throw APIError.invalidResponse
            }

            return text
        } catch let error as APIError {
            throw error
        } catch {
            let isRetryable = !(error is CancellationError)
            if isRetryable && retryCount > 0 {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                return try await makeRequest(prompt: prompt, maxTokens: maxTokens, temperature: temperature, retryCount: retryCount - 1)
            }
            throw APIError.networkError(error.localizedDescription)
        }
    }

    private func decodeJSON<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)

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
