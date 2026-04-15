import Foundation

// MARK: - Generic Response Wrapper
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

// MARK: - User Profile
struct UserProfile: Decodable {
    let uid: String
    let email: String
    let name: String?
    let photo: String?
    let credits: Int
    let isPro: Bool
    let usage: UserUsage?
    let memberSince: String?

    enum CodingKeys: String, CodingKey {
        case uid, email, name, photo, credits, usage
        case isPro = "is_pro"
        case memberSince = "member_since"
    }
}

struct UserUsage: Decodable {
    let todayTotal: Int
    let todaySuccess: Int
    let allTime: Int

    enum CodingKeys: String, CodingKey {
        case todayTotal = "today_total"
        case todaySuccess = "today_success"
        case allTime = "all_time"
    }
}

// MARK: - Category
struct CategoryItem: Decodable, Identifiable {
    let id: Int
    let slug: String
    let name: String
    let description: String?
    let iconUrl: String?
    let isActive: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, slug, name, description
        case iconUrl = "icon_url"
        case isActive = "is_active"
        case sortOrder = "sort_order"
    }
}

struct CategoriesResponse: Decodable {
    let categories: [CategoryItem]
}

// MARK: - Template
struct TemplateItem: Decodable, Identifiable {
    let id: Int
    let appId: String
    let slug: String
    let name: String
    let description: String?
    let actionType: String
    let prompt: String
    let negativePrompt: String?
    let provider: String
    let model: String?
    let categoryId: Int?
    let beforeMediaUrl: String?
    let beforeMediaType: String?
    let afterMediaUrl: String?
    let afterMediaType: String?
    let iconUrl: String?
    let creditCost: Int
    let isActive: Bool
    let isFeatured: Bool
    let isPremium: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, slug, name, description, prompt, provider, model
        case appId = "app_id"
        case actionType = "action_type"
        case negativePrompt = "negative_prompt"
        case categoryId = "category_id"
        case beforeMediaUrl = "before_media_url"
        case beforeMediaType = "before_media_type"
        case afterMediaUrl = "after_media_url"
        case afterMediaType = "after_media_type"
        case iconUrl = "icon_url"
        case creditCost = "credit_cost"
        case isActive = "is_active"
        case isFeatured = "is_featured"
        case isPremium = "is_premium"
        case sortOrder = "sort_order"
    }
}

struct TemplatesResponse: Decodable {
    let templates: [TemplateItem]
}

// MARK: - Slider
struct SliderItem: Decodable, Identifiable {
    let id: Int
    let templateId: Int?
    let title: String?
    let description: String?
    let imageUrl: String?
    let frameUrl: String?
    let deepLink: String?
    let sortOrder: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case templateId = "template_id"
        case imageUrl = "image_url"
        case frameUrl = "frame_url"
        case deepLink = "deep_link"
        case sortOrder = "sort_order"
        case isActive = "is_active"
    }
}

struct SliderResponse: Decodable {
    let slider: [SliderItem]
}

// MARK: - History
struct HistoryItem: Decodable, Identifiable {
    let id: Int
    let provider: String
    let model: String?
    let prompt: String?
    let imageUrl: String?
    let resultUrl: String?
    let status: String
    let durationMs: Int?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, provider, model, prompt, status
        case imageUrl = "image_url"
        case resultUrl = "result_url"
        case durationMs = "duration_ms"
        case createdAt = "created_at"
    }
}

struct HistoryResponse: Decodable {
    let history: [HistoryItem]
    let total: Int
    let page: Int
    let limit: Int
}

// MARK: - Onboarding
struct OnboardingMedia: Decodable, Identifiable {
    let id: Int
    let type: String
    let title: String?
    let description: String?
    let mediaUrl: String
    let thumbnailUrl: String?
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, type, title, description
        case mediaUrl = "media_url"
        case thumbnailUrl = "thumbnail_url"
        case sortOrder = "sort_order"
    }
}

struct OnboardingResponse: Decodable {
    let onboarding: [OnboardingMedia]
}

// MARK: - Reviews
struct UserReview: Decodable, Identifiable {
    let id: Int
    let nickname: String
    let photoUrl: String?
    let review: String
    let rating: Int
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, nickname, review, rating
        case photoUrl = "photo_url"
        case sortOrder = "sort_order"
    }
}

struct ReviewsResponse: Decodable {
    let reviews: [UserReview]
}

// MARK: - Upload
struct UploadResult: Decodable {
    let url: String
    let filename: String
    let size: Int?
}

// MARK: - Transform
struct TransformRequest: Encodable {
    let provider: String
    let model: String?
    let imageUrl: String
    let prompt: String
    let negativePrompt: String?
    let params: [String: String]?

    enum CodingKeys: String, CodingKey {
        case provider, model, prompt, params
        case imageUrl = "image_url"
        case negativePrompt = "negative_prompt"
    }
}

struct TransformResult: Decodable {
    let resultUrl: String
    let provider: String
    let model: String?

    enum CodingKeys: String, CodingKey {
        case provider, model
        case resultUrl = "result_url"
    }
}

// MARK: - Provider
struct ProviderItem: Decodable, Identifiable {
    var id: String { name }
    let name: String
    let active: Bool
}

struct ProvidersResponse: Decodable {
    let providers: [ProviderItem]
}

// MARK: - API Error
enum APIError: LocalizedError {
    case unauthorized
    case rateLimited(retryAfter: Int)
    case serverError(String)
    case invalidInput
    case decodingError

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Please sign in to continue."
        case .rateLimited(let secs): return "Rate limit reached. Try again in \(secs)s."
        case .serverError(let msg): return msg
        case .invalidInput: return "Invalid input provided."
        case .decodingError: return "Unexpected server response."
        }
    }
}
