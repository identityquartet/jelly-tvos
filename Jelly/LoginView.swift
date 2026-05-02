import SwiftUI

struct LoginView: View {
    @Environment(JellyfinAPI.self) private var api
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(hex: "111111").ignoresSafeArea()

            VStack(spacing: 50) {
                VStack(spacing: 8) {
                    Text("Jelly")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text("Jellyfin for Apple TV")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

                VStack(spacing: 20) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }

                    Button("Sign In") {
                        Task { await signIn() }
                    }
                    .disabled(isLoading || username.isEmpty || password.isEmpty)
                    .padding(.top, 10)
                }
                .frame(maxWidth: 550)
            }

            if isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView().progressViewStyle(.circular).scaleEffect(2)
            }
        }
    }

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await api.authenticate(username: username, password: password)
        } catch {
            errorMessage = "Sign in failed. Check your credentials and server URL."
        }
        isLoading = false
    }
}
