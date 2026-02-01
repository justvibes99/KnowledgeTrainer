import SwiftUI
import SwiftData

@main
struct KnowledgeTrainerApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Topic.self,
            QuestionRecord.self,
            ReviewItem.self,
            DeepDive.self,
            DailyStreak.self,
            SubtopicProgress.self,
            WantToLearnItem.self,
            ScholarProfile.self,
            Achievement.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding && KeychainManager.hasKey() {
                HomeView()
                    .onAppear { ensureScholarProfile() }
            } else {
                OnboardingView(isOnboarded: $hasCompletedOnboarding)
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func ensureScholarProfile() {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<ScholarProfile>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        if count == 0 {
            context.insert(ScholarProfile())
            try? context.save()
        }
    }
}
