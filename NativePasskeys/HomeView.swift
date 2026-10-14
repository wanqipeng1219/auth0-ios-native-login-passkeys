import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome, \(viewModel.userName)!")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)

            ScrollView {
                Text(viewModel.idToken)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button("Logout", role: .destructive) {
                viewModel.logout()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.bottom)
        }
        .padding()
        .task {
            await viewModel.loadUserProfile()
        }
    }
}
