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
            Achievement.self,
            CachedQuestion.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        ToggleAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(isOnboarded: $hasCompletedOnboarding)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
