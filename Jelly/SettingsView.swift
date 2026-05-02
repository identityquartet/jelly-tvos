import SwiftUI

struct SettingsView: View {
    @Environment(JellyfinAPI.self) private var api
    @State private var serverURL = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "111111").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 50) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account")
                            .font(.headline)
                            .foregroundStyle(.gray)

                        HStack {
                            Text("Signed in as")
                                .foregroundStyle(.gray)
                            Text(api.username ?? "—")
                                .foregroundStyle(.white)
                                .fontWeight(.medium)
                        }

                        Button("Sign Out") { api.signOut() }
                            .foregroundStyle(.red)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Server")
                            .font(.headline)
                            .foregroundStyle(.gray)

                        TextField("Server URL", text: $serverURL)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .frame(maxWidth: 700)
                            .onSubmit { api.serverURL = serverURL }

                        Text("Press Select to confirm changes")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    Spacer()
                }
                .padding(.horizontal, 70)
                .padding(.top, 60)
            }
            .navigationTitle("Settings")
        }
        .onAppear { serverURL = api.serverURL }
    }
}
