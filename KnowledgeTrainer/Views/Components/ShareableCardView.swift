import SwiftUI

struct ShareableCardView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content

            HStack {
                Spacer()
                Text("SNAPSTUDY")
                    .font(.caption2)
                    .fontWeight(.black)
                    .tracking(2)
                    .foregroundStyle(Color.brutalBlack.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .padding(.top, 8)
        }
        .background(Color.brutalBackground)
        .overlay(
            Rectangle()
                .stroke(Color.brutalBlack, lineWidth: 3)
        )
        .background(
            Rectangle()
                .fill(Color.brutalBlack)
                .offset(x: 6, y: 6)
        )
    }
}
