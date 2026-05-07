import SwiftUI

struct ModelPickerView: View {
    @Binding var selectedModelId: String
    @Environment(\.dismiss) private var dismiss

    @State private var models: [OpenRouterModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var settings = AppSettings.shared

    private var filteredModels: [OpenRouterModel] {
        guard !searchText.isEmpty else { return models }
        return models.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var favorites: [OpenRouterModel] {
        filteredModels.filter { settings.isFavorite($0.id) }
    }

    private var others: [OpenRouterModel] {
        filteredModels.filter { !settings.isFavorite($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                if !favorites.isEmpty {
                    Section("Favorites") {
                        ForEach(favorites) { model in
                            row(for: model)
                        }
                    }
                }
                Section(favorites.isEmpty ? "Models" : "All Models") {
                    ForEach(others) { model in
                        row(for: model)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText)
            .overlay {
                if isLoading && models.isEmpty {
                    ProgressView()
                } else if !isLoading && models.isEmpty && errorMessage == nil {
                    ContentUnavailableView("No Models", systemImage: "cpu", description: Text("Pull to refresh."))
                }
            }
            .refreshable {
                await loadModels(forceRefresh: true)
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadModels(forceRefresh: false)
            }
        }
    }

    @ViewBuilder
    private func row(for model: OpenRouterModel) -> some View {
        Button {
            selectedModelId = model.id
            dismiss()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(model.id)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    if let context = model.contextLength {
                        Text("\(context.formatted()) ctx")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    if model.id == selectedModelId {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                    Button {
                        settings.toggleFavorite(model.id)
                    } label: {
                        Image(systemName: settings.isFavorite(model.id) ? "star.fill" : "star")
                            .foregroundStyle(settings.isFavorite(model.id) ? .yellow : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func loadModels(forceRefresh: Bool) async {
        if !forceRefresh, let cached = await ModelCache.shared.load() {
            models = cached.models
            if cached.isFresh { return }
        }
        if AppSettings.shared.apiKey.isEmpty {
            if models.isEmpty {
                errorMessage = "Add your OpenRouter API key in Settings to fetch models."
            }
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let fresh = try await OpenRouterService.shared.fetchModels()
            models = fresh
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}
