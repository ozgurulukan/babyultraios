import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case rateLimited(retryAfter: Int)
    case serverError(String)
    case invalidInput
    case decodingError
    case paymentRequired
    case forbidden
    case badGateway

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Please sign in to continue."
        case .rateLimited(let secs): return "Rate limit reached. Try again in \(secs)s."
        case .serverError(let msg): return msg
        case .invalidInput: return "Invalid input provided."
        case .decodingError: return "Unexpected server response."
        case .paymentRequired: return "Insufficient credits."
        case .forbidden: return "Your account has been restricted."
        case .badGateway: return "AI provider error — please try again."
        }
    }
}

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

struct UserProfile: Decodable {
    let uid: String
    let email: String?
    let name: String?
    let photo: String?
    let credits: Int
    let isPro: Bool
    let usage: UserUsage?
    let rateLimit: RateLimitInfo?
    let memberSince: String?

    enum CodingKeys: String, CodingKey {
        case uid, email, name, photo, credits, usage
        case isPro = "is_pro"
        case rateLimit = "rate_limit"
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

struct RateLimitInfo: Decodable {
    let maxPerWindow: Int
    let windowSeconds: Int

    enum CodingKeys: String, CodingKey {
        case maxPerWindow = "max_per_window"
        case windowSeconds = "window_seconds"
    }
}

struct CategoryItem: Decodable {
    let rawID: Int
    let type: String?
    let slug: String
    let name: String
    let description: String?
    let iconUrl: String?
    let isActive: Bool
    let isVirtual: Bool?
    let filter: String?
    let sortOrder: Int

    var stableID: String { "\(rawID)_\(slug)" }

    enum CodingKeys: String, CodingKey {
        case rawID = "id"
        case type, slug, name, description, filter
        case iconUrl = "icon_url"
        case isActive = "is_active"
        case isVirtual = "is_virtual"
        case sortOrder = "sort_order"
    }
}

extension CategoryItem: Identifiable {
    var id: String { stableID }
}

struct CategoriesResponse: Decodable {
    let categories: [CategoryItem]
}

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
    let referenceImageCount: Int?
    let referenceVideoUrl: String?
    let requireMomPhoto: Bool?
    let requireBabyPhoto: Bool?
    let requireDadPhoto: Bool?
    let hideFromAll: Bool?
    let aspectRatio: String?
    let supportedAspectRatios: String?
    let iconUrl: String?
    let params: String?
    let creditCost: Int
    let isActive: Bool
    let isFeatured: Bool
    let isPopular: Bool
    let isViral: Bool
    let isPremium: Bool
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, slug, name, description, prompt, provider, model, params
        case appId = "app_id"
        case actionType = "action_type"
        case negativePrompt = "negative_prompt"
        case categoryId = "category_id"
        case beforeMediaUrl = "before_media_url"
        case beforeMediaType = "before_media_type"
        case afterMediaUrl = "after_media_url"
        case afterMediaType = "after_media_type"
        case referenceImageCount = "reference_image_count"
        case referenceVideoUrl = "reference_video_url"
        case requireMomPhoto = "require_mom_photo"
        case requireBabyPhoto = "require_baby_photo"
        case requireDadPhoto = "require_dad_photo"
        case hideFromAll = "hide_from_all"
        case aspectRatio = "aspect_ratio"
        case supportedAspectRatios = "supported_aspect_ratios"
        case iconUrl = "icon_url"
        case creditCost = "credit_cost"
        case isActive = "is_active"
        case isFeatured = "is_featured"
        case isPopular = "is_popular"
        case isViral = "is_viral"
        case isPremium = "is_premium"
        case sortOrder = "sort_order"
    }
}

struct TemplatesResponse: Decodable {
    let templates: [TemplateItem]
}

struct SliderItem: Decodable, Identifiable {
    let id: Int
    let appId: String?
    let type: String?
    let templateId: Int?
    let title: String?
    let description: String?
    let imageUrl: String?
    let frameUrl: String?
    let deepLink: String?
    let sortOrder: Int
    let isActive: Bool
    let startsAt: String?
    let endsAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, type
        case appId = "app_id"
        case templateId = "template_id"
        case imageUrl = "image_url"
        case frameUrl = "frame_url"
        case deepLink = "deep_link"
        case sortOrder = "sort_order"
        case isActive = "is_active"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
    }
}

struct SliderResponse: Decodable {
    let slider: [SliderItem]
}

struct QuickButtonItem: Decodable, Identifiable {
    let id: Int
    let appId: String
    let type: String?
    let title: String
    let iconUrl: String?
    let templateId: Int?
    let sortOrder: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, type
        case appId = "app_id"
        case iconUrl = "icon_url"
        case templateId = "template_id"
        case sortOrder = "sort_order"
        case isActive = "is_active"
    }
}

struct QuickButtonsResponse: Decodable {
    let buttons: [QuickButtonItem]
}

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

struct LanguageItem: Decodable {
    let code: String
    let name: String
}

struct LanguagesResponse: Decodable {
    let languages: [LanguageItem]
}

struct UploadResult: Decodable {
    let url: String
    let filename: String
    let size: Int?
}

struct TransformRequest: Encodable {
    let provider: String
    let model: String?
    let imageUrl: String?
    let imageUrls: [String]?
    let videoUrl: String?
    let momImageUrl: String?
    let babyImageUrl: String?
    let dadImageUrl: String?
    let prompt: String
    let negativePrompt: String?
    let params: [String: String]?
    let creditCost: Int
    let notifyWhenDone: Bool

    enum CodingKeys: String, CodingKey {
        case provider, model, prompt, params
        case imageUrl = "image_url"
        case imageUrls = "image_urls"
        case videoUrl = "video_url"
        case momImageUrl = "mom_image_url"
        case babyImageUrl = "baby_image_url"
        case dadImageUrl = "dad_image_url"
        case negativePrompt = "negative_prompt"
        case creditCost = "credit_cost"
        case notifyWhenDone = "notify_when_done"
    }
}

struct TransformResult: Decodable {
    let resultUrl: String
    let provider: String
    let model: String?
    let metadata: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case provider, model, metadata
        case resultUrl = "result_url"
    }
}

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }
}

struct ProviderItem: Decodable, Identifiable {
    var id: String { name }
    let name: String
    let active: Bool
}

struct ProvidersResponse: Decodable {
    let providers: [ProviderItem]
}

struct DeviceTokenRequest: Encodable {
    let token: String
    let platform: String
    let appId: String?
    let locale: String?

    enum CodingKeys: String, CodingKey {
        case token, platform, locale
        case appId = "app_id"
    }
}

struct FirebaseConfig: Decodable {
    let apiKey: String
    let authDomain: String
    let projectId: String
    let appId: String

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case authDomain = "auth_domain"
        case projectId = "project_id"
        case appId = "app_id"
    }
}

struct CreateReportRequest: Encodable {
    let resultUrl: String
    let reason: String
    let details: String?

    enum CodingKeys: String, CodingKey {
        case resultUrl = "result_url"
        case reason
        case details
    }
}

struct SubmitReportResponse: Decodable {
    let id: Int
}
