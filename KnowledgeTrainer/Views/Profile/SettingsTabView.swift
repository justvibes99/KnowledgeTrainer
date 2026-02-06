import SwiftUI

struct SettingsTabView: View {
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        SettingsView(viewModel: viewModel, isSheet: false)
    }
}
