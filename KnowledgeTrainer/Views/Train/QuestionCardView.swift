import SwiftUI

struct QuestionCardView: View {
    let question: GeneratedQuestion
    @Binding var userAnswer: String
    let isSubmitted: Bool
    let isCorrect: Bool
    var subtopicQuestionNumber: Int? = nil
    let onSubmit: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var borderColor: Color {
        guard isSubmitted else { return .brutalBlack }
        return isCorrect ? .brutalTeal : .brutalCoral
    }

    var body: some View {
        VStack(spacing: 20) {
            // Subtopic label
            HStack(spacing: 6) {
                Text(question.subtopic)
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .foregroundColor(.white)

                if let num = subtopicQuestionNumber, num > 0 {
                    Text("Q\(num)")
                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.brutalBlack)

            // Question text
            Text(question.questionText)
                .font(.system(.title3, design: .default, weight: .semibold))
                .foregroundColor(.brutalBlack)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            // Answer area
            if question.isMultipleChoice {
                multipleChoiceView
            } else {
                typeInView
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.flatSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isSubmitted ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .onAppear {
            if !isSubmitted && !question.isMultipleChoice {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Type-in Answer

    @ViewBuilder
    private var typeInView: some View {
        if !isSubmitted {
            TextField("Your answer...", text: $userAnswer)
                .font(.system(.body, design: .default))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.flatSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.flatBorder, lineWidth: 1)
                )
                .focused($isTextFieldFocused)
                .onSubmit { onSubmit() }

            BrutalButton(title: "Submit", color: .brutalYellow, fullWidth: true) {
                onSubmit()
            }
        } else {
            resultView
        }
    }

    // MARK: - Multiple Choice

    @ViewBuilder
    private var multipleChoiceView: some View {
        if let choices = question.choices {
            VStack(spacing: 10) {
                ForEach(choices, id: \.self) { choice in
                    choiceButton(choice)
                }
            }

            if isSubmitted {
                resultView
            }
        }
    }

    @ViewBuilder
    private func choiceButton(_ choice: String) -> some View {
        let isSelected = userAnswer == choice
        let isCorrectChoice = choice.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let showAsCorrect = isSubmitted && isCorrectChoice
        let showAsWrong = isSubmitted && isSelected && !isCorrect

        Button {
            if !isSubmitted {
                userAnswer = choice
                onSubmit()
            }
        } label: {
            HStack(spacing: 12) {
                Text(choice)
                    .font(.system(.body, design: .default, weight: .regular))
                    .foregroundColor(.brutalBlack)
                    .multilineTextAlignment(.leading)

                Spacer()

                if showAsCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.brutalTeal)
                } else if showAsWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.brutalCoral)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                showAsCorrect ? Color.brutalTeal.opacity(0.15) :
                showAsWrong ? Color.brutalCoral.opacity(0.15) :
                isSelected ? Color.brutalYellow.opacity(0.3) :
                Color.white
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        showAsCorrect ? Color.brutalTeal :
                        showAsWrong ? Color.brutalCoral :
                        Color.brutalBlack,
                        lineWidth: 1
                    )
            )
        }
        .disabled(isSubmitted)
    }

    // MARK: - Result Display

    @ViewBuilder
    private var resultView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(isCorrect ? .brutalTeal : .brutalCoral)

                Text(isCorrect ? "Correct" : "Incorrect")
                    .font(.system(.body, design: .monospaced, weight: .medium))
                    .foregroundColor(.brutalBlack)
            }

            if !isCorrect && !question.isMultipleChoice {
                VStack(spacing: 4) {
                    Text("Correct Answer")
                        .font(.system(.caption2, design: .monospaced, weight: .medium))
                        .foregroundColor(.flatSecondaryText)
                    Text(question.correctAnswer)
                        .font(.system(.body, design: .default, weight: .medium))
                        .foregroundColor(.brutalBlack)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.brutalCoral.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.brutalCoral, lineWidth: 1)
                )
            }
        }
    }
}
