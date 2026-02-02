import SwiftUI

struct BrutalTextField: View {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(.body, design: .default))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? Color.flatBorderStrong : Color.flatBorder, lineWidth: 1)
            )
            .shadow(color: isFocused ? Color.brutalYellow.opacity(0.1) : .clear, radius: 3, x: 0, y: 0)
            .focused($isFocused)
            .onSubmit {
                onSubmit?()
            }
    }
}
