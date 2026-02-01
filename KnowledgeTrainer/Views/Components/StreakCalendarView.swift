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

    private func questionsCount(on date: Date) -> Int {
        let calendar = Calendar.current
        return dailyStreaks
            .first { calendar.isDate($0.date, inSameDayAs: date) }?
            .questionsCompleted ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LAST 28 DAYS")
                .font(.system(.caption, design: .default, weight: .bold))
                .tracking(1.2)
                .foregroundColor(.brutalBlack)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(last28Days, id: \.self) { date in
                    let active = hasActivity(on: date)
                    Rectangle()
                        .fill(active ? Color.brutalTeal : Color.white)
                        .overlay(
                            Rectangle()
                                .stroke(Color.brutalBlack, lineWidth: 1)
                        )
                        .frame(height: 24)
                }
            }
        }
    }
}
