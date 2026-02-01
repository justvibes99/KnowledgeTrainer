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
                Text(question.subtopic.uppercased())
                    .font(.system(.caption2, design: .default, weight: .bold))
                    .tracking(1.5)
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
                .font(.system(.title3, design: .default, weight: .bold))
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
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(borderColor, lineWidth: isSubmitted ? 4 : 3)
        )
        .background(
            Rectangle()
                .fill(Color.brutalBlack)
                .offset(x: 8, y: 8)
        )
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
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.brutalBlack, lineWidth: 3)
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
        let isCorrectChoice = choice == question.correctAnswer
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
                    .font(.system(.body, design: .default, weight: isSelected ? .bold : .regular))
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
                Rectangle()
                    .stroke(
                        showAsCorrect ? Color.brutalTeal :
                        showAsWrong ? Color.brutalCoral :
                        Color.brutalBlack,
                        lineWidth: (showAsCorrect || showAsWrong) ? 3 : 2
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

                Text(isCorrect ? "CORRECT" : "INCORRECT")
                    .font(.system(.body, design: .default, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(.brutalBlack)
            }

            if !isCorrect && !question.isMultipleChoice {
                VStack(spacing: 4) {
                    Text("CORRECT ANSWER")
                        .font(.system(.caption2, design: .default, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.brutalBlack.opacity(0.6))
                    Text(question.correctAnswer)
                        .font(.system(.body, design: .default, weight: .bold))
                        .foregroundColor(.brutalBlack)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.brutalCoral.opacity(0.15))
                .overlay(
                    Rectangle()
                        .stroke(Color.brutalCoral, lineWidth: 2)
                )
            }
        }
    }
}
