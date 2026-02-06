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
                Text("XP Earned")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brutalBlack)

                Spacer()

                Text("+\(totalXP) XP")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(Color.brutalTeal)
            }

            if isPerfectSession {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Perfect Session")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.brutalBlack)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.brutalYellow)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.flatBorder, lineWidth: 1)
                )
            }

            ForEach(xpEvents) { event in
                HStack {
                    Text("+\(event.amount) XP")
                        .font(.subheadline)
                        .fontWeight(.medium)
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
        .brutalCard(backgroundColor: .brutalSurface)
    }
}
