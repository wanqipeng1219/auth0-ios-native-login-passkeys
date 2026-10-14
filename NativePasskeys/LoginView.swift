import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var email = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Welcome to Native Login\nwith Passkeys!")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal)

            if viewModel.isLoading {
                ProgressView()
            }

            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Button("Login") {
                Task { await viewModel.loginWithPasskey() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading)

            Text("or")
                .foregroundStyle(.secondary)

            Button("Sign Up") {
                Task { await viewModel.signUpWithPasskey(email: email) }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(email.isEmpty || viewModel.isLoading)

            Spacer()
        }
        .padding()
    }
}
