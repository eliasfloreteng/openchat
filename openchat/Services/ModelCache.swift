import Foundation

actor ModelCache {
    static let shared = ModelCache()

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("openrouter_models.json")
    }()

    private let maxAge: TimeInterval = 60 * 60 * 6 // 6 hours

    func load() -> (models: [OpenRouterModel], isFresh: Bool)? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let cached = try JSONDecoder().decode(CachedModels.self, from: data)
            let isFresh = Date().timeIntervalSince(cached.cachedAt) < maxAge
            return (cached.models, isFresh)
        } catch {
            return nil
        }
    }

    func save(_ models: [OpenRouterModel]) {
        let cached = CachedModels(cachedAt: .now, models: models)
        do {
            let data = try JSONEncoder().encode(cached)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Cache failure is non-fatal
        }
    }

    private struct CachedModels: Codable {
        let cachedAt: Date
        let models: [OpenRouterModel]
    }
}
