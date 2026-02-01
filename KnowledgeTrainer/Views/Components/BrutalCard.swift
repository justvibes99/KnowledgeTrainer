import SwiftUI

struct BrutalCard<Content: View>: View {
    var backgroundColor: Color = .white
    var shadowSize: CGFloat = 8
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .stroke(Color.brutalBlack, lineWidth: 3)
        )
        .background(
            Rectangle()
                .fill(Color.brutalBlack)
                .offset(x: shadowSize, y: shadowSize)
        )
    }
}
