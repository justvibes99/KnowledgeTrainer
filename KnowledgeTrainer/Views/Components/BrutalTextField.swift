import SwiftUI

struct BrutalTextField: View {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.flatSecondaryText)
                    .padding(.horizontal, 14)
            }
            TextField("", text: $text)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.brutalBlack)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.flatBorderStrong, lineWidth: 2)
        )
    }
}
