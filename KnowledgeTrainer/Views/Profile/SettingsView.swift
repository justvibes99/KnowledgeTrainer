import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ProfileViewModel

    @State private var apiKey: String = ""
    @State private var showAPIKey = false
    @State private var apiKeyStatus: String = ""
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brutalBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("SETTINGS")
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .tracking(1.5)
                            .foregroundColor(.brutalBlack)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // API Key Section
                        settingsSection(title: "API KEY") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    if showAPIKey {
                                        TextField("API Key", text: $apiKey)
                                            .font(.system(.caption, design: .monospaced))
                                    } else {
                                        Text(KeychainManager.hasKey() ? "sk-ant-****" : "No key set")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.brutalBlack.opacity(0.6))
                                    }
                                    Spacer()
                                    Button(action: { showAPIKey.toggle() }) {
                                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                            .foregroundColor(.brutalBlack)
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.brutalBlack, lineWidth: 2)
                                )

                                if !apiKeyStatus.isEmpty {
                                    Text(apiKeyStatus)
                                        .font(.system(.caption, design: .default, weight: .bold))
                                        .foregroundColor(.brutalBlack)
                                }

                                HStack(spacing: 8) {
                                    BrutalButton(title: "Save Key", color: .brutalTeal) {
                                        saveAPIKey()
                                    }
                                    BrutalButton(title: "Delete Key", color: .brutalCoral) {
                                        deleteAPIKey()
                                    }
                                }
                            }
                        }

                        // Timer Section
                        settingsSection(title: "TIMER") {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: Binding(
                                    get: { viewModel.timerEnabled },
                                    set: { viewModel.timerEnabled = $0; viewModel.saveTimerSettings() }
                                )) {
                                    Text("ENABLE TIMER")
                                        .font(.system(.caption, design: .default, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(.brutalBlack)
                                }
                                .tint(.brutalTeal)

                                if viewModel.timerEnabled {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("DURATION")
                                            .font(.system(.caption2, design: .default, weight: .bold))
                                            .tracking(1)
                                            .foregroundColor(.brutalBlack)

                                        HStack(spacing: 8) {
                                            ForEach([10, 15, 30], id: \.self) { duration in
                                                BrutalChip(
                                                    title: "\(duration)s",
                                                    isSelected: viewModel.timerDuration == duration,
                                                    color: .brutalYellow
                                                ) {
                                                    viewModel.timerDuration = duration
                                                    viewModel.saveTimerSettings()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Reminders Section
                        settingsSection(title: "DAILY REMINDER") {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: Binding(
                                    get: { viewModel.reminderEnabled },
                                    set: {
                                        viewModel.reminderEnabled = $0
                                        if $0 {
                                            Task {
                                                let _ = await NotificationManager.requestPermission()
                                            }
                                        }
                                        viewModel.saveReminderSettings()
                                    }
                                )) {
                                    Text("ENABLE REMINDER")
                                        .font(.system(.caption, design: .default, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(.brutalBlack)
                                }
                                .tint(.brutalTeal)

                                if viewModel.reminderEnabled {
                                    DatePicker(
                                        "TIME",
                                        selection: Binding(
                                            get: { viewModel.reminderTime },
                                            set: { viewModel.reminderTime = $0; viewModel.saveReminderSettings() }
                                        ),
                                        displayedComponents: .hourAndMinute
                                    )
                                    .font(.system(.caption, design: .default, weight: .bold))
                                    .foregroundColor(.brutalBlack)
                                }
                            }
                        }

                        // Reset Section
                        settingsSection(title: "DANGER ZONE") {
                            BrutalButton(title: "Reset All Data", color: .brutalCoral, fullWidth: true) {
                                showResetAlert = true
                            }
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("DONE")
                            .font(.system(.body, design: .default, weight: .bold))
                            .foregroundColor(.brutalBlack)
                    }
                    .buttonStyle(.plain)
                }
            }
            .brutalAlert(
                isPresented: $showResetAlert,
                title: "Reset All Data?",
                message: "This will permanently delete all topics, questions, review items, deep dives, and your API key. This cannot be undone.",
                primaryButton: BrutalAlertButton(title: "Reset", isDestructive: true) {
                    viewModel.resetAllData(modelContext: modelContext)
                    dismiss()
                },
                secondaryButton: BrutalAlertButton(title: "Cancel") {}
            )
        }
        .onAppear {
            if let key = KeychainManager.retrieve() {
                apiKey = key
            }
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.caption, design: .default, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.brutalBlack)

            content()
                .padding(16)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .stroke(Color.brutalBlack, lineWidth: 3)
                )
                .background(
                    Rectangle()
                        .fill(Color.brutalBlack)
                        .offset(x: 4, y: 4)
                )
        }
        .padding(.horizontal, 24)
    }

    private func saveAPIKey() {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            apiKeyStatus = "Please enter an API key"
            return
        }
        do {
            try KeychainManager.save(apiKey: key)
            apiKeyStatus = "Key saved successfully"
            showAPIKey = false
        } catch {
            apiKeyStatus = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func deleteAPIKey() {
        do {
            try KeychainManager.delete()
            apiKey = ""
            apiKeyStatus = "Key deleted"
            showAPIKey = false
        } catch {
            apiKeyStatus = "Failed to delete: \(error.localizedDescription)"
        }
    }
}
