import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ProfileViewModel

    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brutalBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Settings")
                            .font(.system(size: 28, weight: .semibold, design: .monospaced))
                            .foregroundColor(.brutalBlack)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Timer Section
                        settingsSection(title: "Timer") {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: Binding(
                                    get: { viewModel.timerEnabled },
                                    set: { viewModel.timerEnabled = $0; viewModel.saveTimerSettings() }
                                )) {
                                    Text("Enable Timer")
                                        .font(.system(.caption, design: .monospaced, weight: .medium))
                                        .foregroundColor(.brutalBlack)
                                }
                                .tint(.brutalTeal)

                                if viewModel.timerEnabled {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Duration")
                                            .font(.system(.caption2, design: .monospaced, weight: .medium))
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

                        // Learning Depth Section
                        settingsSection(title: "Learning Depth") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Controls lesson detail and question complexity")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(.flatSecondaryText)

                                HStack(spacing: 8) {
                                    ForEach(LearningDepth.allCases, id: \.self) { depth in
                                        BrutalChip(
                                            title: depth.displayName,
                                            isSelected: viewModel.learningDepth == depth,
                                            color: .brutalTeal
                                        ) {
                                            viewModel.learningDepth = depth
                                            viewModel.saveLearningDepth()
                                        }
                                    }
                                }
                            }
                        }

                        // Reminders Section
                        settingsSection(title: "Daily Reminder") {
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
                                    Text("Enable Reminder")
                                        .font(.system(.caption, design: .monospaced, weight: .medium))
                                        .foregroundColor(.brutalBlack)
                                }
                                .tint(.brutalTeal)

                                if viewModel.reminderEnabled {
                                    DatePicker(
                                        "Time",
                                        selection: Binding(
                                            get: { viewModel.reminderTime },
                                            set: { viewModel.reminderTime = $0; viewModel.saveReminderSettings() }
                                        ),
                                        displayedComponents: .hourAndMinute
                                    )
                                    .font(.system(.caption, design: .monospaced, weight: .medium))
                                    .foregroundColor(.brutalBlack)
                                }
                            }
                        }

                        // Reset Section
                        settingsSection(title: "Danger Zone") {
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
                    Button("Done") { dismiss() }
                }            }
            .brutalAlert(
                isPresented: $showResetAlert,
                title: "Reset All Data?",
                message: "This will permanently delete all topics, questions, review items, and deep dives. This cannot be undone.",
                primaryButton: BrutalAlertButton(title: "Reset", isDestructive: true) {
                    viewModel.resetAllData(modelContext: modelContext)
                    dismiss()
                },
                secondaryButton: BrutalAlertButton(title: "Cancel") {}
            )
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(.caption, design: .monospaced, weight: .medium))
                .foregroundColor(.brutalBlack)

            content()
                .padding(16)
                .background(Color.flatSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.flatBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 24)
    }
}
