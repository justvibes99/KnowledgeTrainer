import SwiftUI

struct BrutalTextField: View {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(.body, design: .default))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.brutalBlack, lineWidth: 3)
            )
            .background(
                Rectangle()
                    .fill(Color.brutalBlack)
                    .offset(x: isFocused ? 4 : 0, y: isFocused ? 4 : 0)
            )
            .focused($isFocused)
            .onSubmit {
                onSubmit?()
            }
    }
}
