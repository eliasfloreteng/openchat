import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = AppSettings.shared
    @State private var apiKeyDraft: String = ""
    @State private var revealKey: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Group {
                            if revealKey {
                                TextField("sk-or-...", text: $apiKeyDraft)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("sk-or-...", text: $apiKeyDraft)
                            }
                        }
                        .font(.body.monospaced())
                        Button {
                            revealKey.toggle()
                        } label: {
                            Image(systemName: revealKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("OpenRouter API Key")
                } footer: {
                    Text("Stored securely in the iOS Keychain. Get a key at openrouter.ai/keys.")
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { settings.webSearchEnabled },
                        set: { settings.webSearchEnabled = $0 }
                    )) {
                        Label("Web Search", systemImage: "magnifyingglass")
                    }
                    Toggle(isOn: Binding(
                        get: { settings.webFetchEnabled },
                        set: { settings.webFetchEnabled = $0 }
                    )) {
                        Label("Web Fetch", systemImage: "link")
                    }
                } header: {
                    Text("Server Tools")
                } footer: {
                    Text("Enables OpenRouter's built-in plugins so models can search the web and read URLs in messages.")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                    Link(destination: URL(string: "https://openrouter.ai/docs")!) {
                        Label("OpenRouter Docs", systemImage: "book")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        settings.apiKey = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                apiKeyDraft = settings.apiKey
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
