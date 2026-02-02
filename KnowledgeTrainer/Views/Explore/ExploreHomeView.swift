import SwiftUI
import SwiftData

struct ExploreHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DeepDive.dateCreated, order: .reverse) private var deepDives: [DeepDive]

    @State private var viewModel = ExploreViewModel()
    @State private var selectedDeepDive: DeepDive?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brutalBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Text("Explore")
                            .font(.system(size: 36, weight: .semibold, design: .monospaced))
                            .foregroundColor(.brutalBlack)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        // Search
                        VStack(spacing: 12) {
                            BrutalTextField(
                                placeholder: "Deep dive into any topic...",
                                text: $viewModel.searchText,
                                onSubmit: { Task { await viewModel.generateDeepDive(modelContext: modelContext) } }
                            )

                            if viewModel.isLoading {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.brutalBlack)
                                    Text("Generating deep dive...")
                                        .font(.system(.caption, design: .monospaced, weight: .medium))
                                        .foregroundColor(.brutalBlack)
                                }
                                .padding(.vertical, 8)
                            } else {
                                BrutalButton(title: "Explore", color: .brutalTeal, fullWidth: true) {
                                    Task { await viewModel.generateDeepDive(modelContext: modelContext) }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        // Current Deep Dive
                        if let deepDive = viewModel.currentDeepDive {
                            DeepDiveView(deepDive: deepDive, onTopicTap: { topic in
                                viewModel.searchText = topic
                            })
                            .padding(.horizontal, 24)
                        }

                        // Saved Library
                        SavedLibraryView(
                            deepDives: viewModel.filteredDeepDives(deepDives),
                            filterText: $viewModel.filterText,
                            onSelect: { selectedDeepDive = $0 },
                            onDelete: { viewModel.deleteDeepDive($0, modelContext: modelContext) }
                        )
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 100)
                    }
                }
            }
            .sheet(item: $selectedDeepDive) { deepDive in
                NavigationStack {
                    ScrollView {
                        DeepDiveView(deepDive: deepDive, onTopicTap: { topic in
                            selectedDeepDive = nil
                            viewModel.searchText = topic
                        })
                        .padding(24)
                    }
                    .background(Color.brutalBackground)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { selectedDeepDive = nil }
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
}
