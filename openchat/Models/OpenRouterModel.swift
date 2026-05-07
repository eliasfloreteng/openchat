import Foundation

struct OpenRouterModel: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let contextLength: Int?
    let pricing: Pricing?

    struct Pricing: Codable, Hashable {
        let prompt: String?
        let completion: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, name, description, pricing
        case contextLength = "context_length"
    }
}

struct OpenRouterModelsResponse: Codable {
    let data: [OpenRouterModel]
}
