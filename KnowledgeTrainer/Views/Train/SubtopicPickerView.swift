import SwiftUI
import SwiftData

struct LearningPathView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var reviewItems: [ReviewItem]
    @Query private var subtopicProgress: [SubtopicProgress]

    let topic: Topic
    var initialQuestions: [GeneratedQuestion] = []
    var initialLesson: LessonPayload?

    @State private var selectedSubtopic: String?
    @State private var navigateToModule = false
    @State private var isCreatingBranch = false
    @State private var branchTopic: Topic?
    @State private var branchQuestions: [GeneratedQuestion] = []
    @State private var branchLesson: LessonPayload?
    @State private var navigateToBranch = false
    @State private var didAutoNavigate = false
    @State private var showQueueToast = false

    private var topicProgress: [SubtopicProgress] {
        subtopicProgress
            .filter { $0.topicID == topic.id }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var masteredCount: Int {
        topicProgress.filter { $0.isMastered }.count
    }

    private var currentSubtopic: SubtopicProgress? {
        topicProgress.first { !$0.isMastered }
    }

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(topic.name.uppercased())
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .tracking(1.5)
                        .foregroundColor(.brutalBlack)

                    if !topicProgress.isEmpty {
                        HStack(spacing: 8) {
                            Text("\(masteredCount)/\(topicProgress.count) MASTERED")
                                .font(.system(.caption, design: .default, weight: .bold))
                                .tracking(1)
                                .foregroundColor(.brutalBlack)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.brutalBlack.opacity(0.15))
                                        .frame(height: 8)

                                    Rectangle()
                                        .fill(Color.brutalTeal)
                                        .frame(width: topicProgress.isEmpty ? 0 : geo.size.width * CGFloat(masteredCount) / CGFloat(topicProgress.count), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    } else {
                        Text("LEARNING PATH")
                            .font(.system(.caption, design: .default, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(.brutalBlack)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)

                // Learning Path
                ScrollView {
                    VStack(spacing: 0) {
                        // Start / Continue Button
                        if let current = currentSubtopic {
                            BrutalButton(
                                title: current.questionsAnswered > 0 ? "Continue: \(current.subtopicName)" : "Start: \(current.subtopicName)",
                                color: .brutalYellow,
                                fullWidth: true
                            ) {
                                selectedSubtopic = current.subtopicName
                                navigateToModule = true
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        } else if !topicProgress.isEmpty {
                            // All mastered
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title3)
                                    .foregroundColor(.brutalTeal)
                                Text("ALL MODULES MASTERED")
                                    .font(.system(.caption, design: .default, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundColor(.brutalBlack)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        }

                        if topicProgress.isEmpty {
                            legacySubtopicView
                        } else {
                            orderedPathView
                        }

                        // Related Topics Section
                        if !topic.relatedTopics.isEmpty {
                            relatedTopicsSection
                                .padding(.top, 24)
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }

            // Queue toast
            if showQueueToast {
                VStack {
                    Spacer()
                    Text("ADDED TO QUEUE")
                        .font(.system(.caption, design: .default, weight: .bold))
                        .tracking(1.2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.brutalBlack)
                        .padding(.bottom, 40)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.body.bold())
                        .foregroundColor(.brutalBlack)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationDestination(isPresented: $navigateToModule) {
            if let selected = selectedSubtopic {
                ModuleFlowView(
                    topic: topic,
                    subtopicName: selected,
                    initialQuestions: selected == topicProgress.first?.subtopicName ? initialQuestions : [],
                    initialLesson: selected == initialLesson?.subtopic ? initialLesson : nil
                )
            }
        }
        .navigationDestination(isPresented: $navigateToBranch) {
            if let branchTopic {
                LearningPathView(
                    topic: branchTopic,
                    initialQuestions: branchQuestions,
                    initialLesson: branchLesson
                )
            }
        }
        .onAppear { }
    }

    // MARK: - Ordered Path View

    @ViewBuilder
    private var orderedPathView: some View {
        VStack(spacing: 0) {
            ForEach(Array(topicProgress.enumerated()), id: \.element.id) { index, progress in
                HStack(spacing: 16) {
                    // Status indicator + connecting line
                    VStack(spacing: 0) {
                        if index > 0 {
                            Rectangle()
                                .fill(topicProgress[index - 1].isMastered ? Color.brutalTeal : Color.brutalBlack.opacity(0.15))
                                .frame(width: 3, height: 16)
                        } else {
                            Spacer().frame(height: 16)
                        }

                        statusIcon(for: progress)

                        if index < topicProgress.count - 1 {
                            Rectangle()
                                .fill(progress.isMastered ? Color.brutalTeal : Color.brutalBlack.opacity(0.15))
                                .frame(width: 3, height: 16)
                        } else {
                            Spacer().frame(height: 16)
                        }
                    }
                    .frame(width: 36)

                    // Subtopic card — all tappable
                    subtopicRow(progress: progress)

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private func statusIcon(for progress: SubtopicProgress) -> some View {
        if progress.isMastered {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.brutalTeal)
        } else if progress.subtopicName == currentSubtopic?.subtopicName {
            Circle()
                .fill(Color.brutalYellow)
                .frame(width: 28, height: 28)
                .overlay(
                    Circle()
                        .stroke(Color.brutalBlack, lineWidth: 3)
                )
        } else {
            Circle()
                .fill(Color.white)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.brutalBlack.opacity(0.3), lineWidth: 2)
                )
        }
    }

    @ViewBuilder
    private func subtopicRow(progress: SubtopicProgress) -> some View {
        let isCurrent = progress.subtopicName == currentSubtopic?.subtopicName
        let isFuture = !progress.isMastered && !isCurrent

        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(progress.subtopicName.uppercased())
                    .font(.system(.caption, design: .default, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(isFuture ? .brutalBlack.opacity(0.4) : .brutalBlack)
                    .lineLimit(2)

                if progress.questionsAnswered > 0 {
                    HStack(spacing: 8) {
                        Text("\(progress.questionsAnswered) Qs")
                            .font(.system(.caption2, design: .default))
                            .foregroundColor(.brutalBlack.opacity(0.6))

                        Text("\(Int(progress.accuracy))%")
                            .font(.system(.caption2, design: .monospaced, weight: .bold))
                            .foregroundColor(progress.accuracy >= 80 ? .brutalTeal : .brutalCoral)
                    }
                }

                if progress.isMastered {
                    Text("MASTERED")
                        .font(.system(.caption2, design: .default, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.brutalTeal)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(isFuture ? .brutalBlack.opacity(0.25) : .brutalBlack.opacity(0.5))
        }
        .padding(.vertical, 8)
        .opacity(isFuture ? 0.6 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedSubtopic = progress.subtopicName
            navigateToModule = true
        }
    }

    // MARK: - Related Topics Section

    @ViewBuilder
    private var relatedTopicsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RELATED TOPICS")
                .font(.system(.caption, design: .default, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.brutalBlack)
                .padding(.horizontal, 24)

            FlowLayout(spacing: 8) {
                ForEach(topic.relatedTopics, id: \.self) { related in
                    Text(related.uppercased())
                        .font(.system(.caption, design: .default, weight: .bold))
                        .tracking(0.8)
                        .foregroundColor(.brutalBlack)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.brutalMint)
                        .overlay(
                            Rectangle()
                                .stroke(Color.brutalBlack, lineWidth: 2)
                        )
                        .onTapGesture {
                            createBranchTopic(name: related)
                        }
                        .onLongPressGesture {
                            queueRelatedTopic(name: related)
                        }
                }
            }
            .padding(.horizontal, 24)

            if isCreatingBranch {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.brutalBlack)
                    Text("CREATING PATH...")
                        .font(.system(.caption2, design: .default, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.brutalBlack)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Legacy Fallback

    @ViewBuilder
    private var legacySubtopicView: some View {
        FlowLayout(spacing: 8) {
            ForEach(topic.subtopics, id: \.self) { subtopic in
                BrutalChip(
                    title: subtopic,
                    isSelected: true,
                    color: .brutalTeal
                ) {}
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func createBranchTopic(name: String) {
        guard !isCreatingBranch else { return }
        isCreatingBranch = true
        Task {
            do {
                let (structure, questions, lesson, relatedTopics, category) = try await APIClient.shared.generateTopicAndFirstBatch(topic: name)

                let newTopic = Topic(
                    name: structure.name,
                    subtopics: structure.subtopics,
                    dateCreated: Date(),
                    lastPracticed: Date(),
                    subtopicsOrdered: true,
                    relatedTopics: relatedTopics,
                    category: category
                )
                modelContext.insert(newTopic)

                for (index, sub) in structure.subtopics.enumerated() {
                    let prog = SubtopicProgress(
                        topicID: newTopic.id,
                        subtopicName: sub,
                        sortOrder: index
                    )
                    if index == 0, let lesson {
                        prog.lessonOverview = lesson.overview
                        prog.lessonKeyFacts = lesson.keyFacts
                        prog.lessonMisconceptions = lesson.misconceptions ?? []
                        prog.lessonConnections = lesson.connections ?? []
                    }
                    modelContext.insert(prog)
                }
                try modelContext.save()

                await MainActor.run {
                    branchTopic = newTopic
                    branchQuestions = questions
                    branchLesson = lesson
                    isCreatingBranch = false
                    navigateToBranch = true
                }
            } catch {
                await MainActor.run {
                    isCreatingBranch = false
                }
            }
        }
    }

    private func queueRelatedTopic(name: String) {
        let item = WantToLearnItem(
            topicName: name,
            sourceTopicID: topic.id
        )
        modelContext.insert(item)
        try? modelContext.save()
        HapticManager.success()

        withAnimation(.easeInOut(duration: 0.3)) {
            showQueueToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                showQueueToast = false
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }

        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}
