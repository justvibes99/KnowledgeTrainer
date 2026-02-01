import SwiftUI

struct SessionXPSummaryView: View {
    let xpEvents: [XPEvent]
    let isPerfectSession: Bool

    var totalXP: Int {
        xpEvents.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("XP EARNED")
                    .font(.headline)
                    .fontWeight(.black)
                    .tracking(2)
                    .foregroundStyle(Color.brutalBlack)

                Spacer()

                Text("+\(totalXP) XP")
                    .font(.title3)
                    .fontWeight(.black)
                    .monospacedDigit()
                    .foregroundStyle(Color.brutalTeal)
            }

            if isPerfectSession {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                    Text("PERFECT SESSION")
                        .font(.caption)
                        .fontWeight(.black)
                        .tracking(1.5)
                }
                .foregroundStyle(Color.brutalBlack)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.brutalYellow)
                .overlay(
                    Rectangle()
                        .stroke(Color.brutalBlack, lineWidth: 3)
                )
            }

            ForEach(xpEvents) { event in
                HStack {
                    Text("+\(event.amount) XP")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundStyle(Color.brutalTeal)
                        .frame(width: 70, alignment: .leading)

                    Text(event.reason)
                        .font(.subheadline)
                        .foregroundStyle(Color.brutalBlack)

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .brutalCard(backgroundColor: .white)
    }
}
