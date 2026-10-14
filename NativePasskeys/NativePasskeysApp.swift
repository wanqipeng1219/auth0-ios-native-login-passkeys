import SwiftUI

@main
struct NativePasskeysApp: App {
    @StateObject private var viewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            if viewModel.isAuthenticated {
                HomeView(viewModel: viewModel)
            } else {
                LoginView(viewModel: viewModel)
            }
        }
    }
}
