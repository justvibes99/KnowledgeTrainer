import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarded: Bool
    @State private var apiKey: String = ""
    @State private var isTesting: Bool = false
    @State private var testResult: String?
    @State private var testSuccess: Bool = false

    var body: some View {
        ZStack {
            Color.brutalBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

                    VStack(spacing: 8) {
                        Text("SNAP")
                            .font(.system(size: 42, weight: .bold, design: .default))
                            .foregroundColor(.brutalBlack)
                        Text("STUDY")
                            .font(.system(size: 42, weight: .bold, design: .default))
                            .foregroundColor(.brutalCoral)
                    }

                    BrutalCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("SETUP")
                                .font(.system(.title3, design: .default, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(.brutalBlack)

                            Text("Enter your Anthropic API key to get started. This is stored securely in your device's Keychain.")
                                .font(.system(.body, design: .default))
                                .foregroundColor(.brutalBlack)

                            BrutalTextField(
                                placeholder: "sk-ant-...",
                                text: $apiKey,
                                onSubmit: nil
                            )

                            if let result = testResult {
                                HStack(spacing: 8) {
                                    Image(systemName: testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(testSuccess ? .brutalTeal : .brutalCoral)
                                    Text(result)
                                        .font(.system(.caption, design: .default, weight: .bold))
                                        .foregroundColor(.brutalBlack)
                                }
                            }

                            if testSuccess {
                                BrutalButton(title: "Continue", color: .brutalYellow, fullWidth: true) {
                                    saveAndContinue()
                                }
                            } else {
                                BrutalButton(title: "Test Connection", color: .brutalTeal, fullWidth: true) {
                                    testConnection()
                                }
                            }

                            if isTesting {
                                ProgressView()
                                    .tint(.brutalBlack)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
        }
    }

    private func testConnection() {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            testResult = "Please enter an API key"
            testSuccess = false
            return
        }

        isTesting = true
        testResult = nil

        Task {
            do {
                try KeychainManager.save(apiKey: key)
                let success = try await APIClient.shared.testConnection()
                await MainActor.run {
                    testSuccess = success
                    testResult = success ? "Connection successful!" : "Connection failed"
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    testSuccess = false
                    testResult = error.localizedDescription
                    isTesting = false
                    try? KeychainManager.delete()
                }
            }
        }
    }

    private func saveAndContinue() {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try KeychainManager.save(apiKey: key)
            isOnboarded = true
        } catch {
            testResult = "Failed to save key: \(error.localizedDescription)"
            testSuccess = false
        }
    }
}
