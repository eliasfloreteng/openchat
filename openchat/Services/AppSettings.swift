import Foundation
import Observation

private enum SettingsKeys {
    static let apiKey = "openrouter.apiKey"
    static let webSearchEnabled = "tools.webSearch"
    static let webFetchEnabled = "tools.webFetch"
    static let favoriteModelIds = "models.favorites"
    static let lastSelectedModel = "models.lastSelected"
}

@Observable
final class AppSettings {
    @MainActor static let shared = AppSettings()

    @ObservationIgnored private let defaults = UserDefaults.standard
    private typealias Keys = SettingsKeys

    var webSearchEnabled: Bool {
        didSet { defaults.set(webSearchEnabled, forKey: Keys.webSearchEnabled) }
    }

    var webFetchEnabled: Bool {
        didSet { defaults.set(webFetchEnabled, forKey: Keys.webFetchEnabled) }
    }

    var favoriteModelIds: Set<String> {
        didSet { defaults.set(Array(favoriteModelIds), forKey: Keys.favoriteModelIds) }
    }

    var lastSelectedModel: String {
        didSet { defaults.set(lastSelectedModel, forKey: Keys.lastSelectedModel) }
    }

    init() {
        let d = UserDefaults.standard
        self.webSearchEnabled = d.object(forKey: Keys.webSearchEnabled) as? Bool ?? true
        self.webFetchEnabled = d.object(forKey: Keys.webFetchEnabled) as? Bool ?? true
        self.favoriteModelIds = Set(d.stringArray(forKey: Keys.favoriteModelIds) ?? [])
        self.lastSelectedModel = d.string(forKey: Keys.lastSelectedModel) ?? "openai/gpt-4o-mini"
    }

    // API key lives in the Keychain, not observed.
    var apiKey: String {
        get { Keychain.get(Keys.apiKey) ?? "" }
        set {
            if newValue.isEmpty {
                Keychain.delete(Keys.apiKey)
            } else {
                Keychain.set(newValue, for: Keys.apiKey)
            }
        }
    }

    func toggleFavorite(_ modelId: String) {
        if favoriteModelIds.contains(modelId) {
            favoriteModelIds.remove(modelId)
        } else {
            favoriteModelIds.insert(modelId)
        }
    }

    func isFavorite(_ modelId: String) -> Bool {
        favoriteModelIds.contains(modelId)
    }
}
