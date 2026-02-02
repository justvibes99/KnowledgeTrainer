import SwiftUI

struct StreakCalendarView: View {
    let dailyStreaks: [DailyStreak]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var last28Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<28).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
    }

    private func hasActivity(on date: Date) -> Bool {
        let calendar = Calendar.current
        return dailyStreaks.contains { streak in
            calendar.isDate(streak.date, inSameDayAs: date) && streak.questionsCompleted > 0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 28 Days")
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundColor(.flatSecondaryText)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(last28Days, id: \.self) { date in
                    let active = hasActivity(on: date)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(active ? Color.brutalTeal : Color.flatSurfaceSubtle)
                        .frame(height: 24)
                }
            }
        }
    }
}
