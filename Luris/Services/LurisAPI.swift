import Foundation
import UIKit

/// High-level API facade for all Luris backend endpoints.
struct LurisAPI {
    static let shared = LurisAPI()
    private init() {}

    private let client = APIClient.shared
    private let appID = "luris"

    private var lang: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    // MARK: - User Profile
    func getProfile() async throws -> UserProfile {
        let response: APIResponse<UserProfile> = try await client.get("/api/v1/me")
        guard response.success, let data = response.data else {
            throw APIError.serverError(response.error ?? "Failed to load profile")
        }
        return data
    }

    // MARK: - Categories
    func getCategories() async throws -> [CategoryItem] {
        let path = "/api/v1/categories?app_id=\(appID)&lang=\(lang)"
        let response: APIResponse<CategoriesResponse> = try await client.get(path)
        return response.data?.categories ?? []
    }

    // MARK: - Templates
    func getTemplates(categoryID: Int? = nil, featured: Bool = false, actionType: String? = nil) async throws -> [TemplateItem] {
        var path = "/api/v1/templates?app_id=\(appID)&lang=\(lang)"
        if let id = categoryID { path += "&category_id=\(id)" }
        if featured { path += "&featured=true" }
        if let at = actionType { path += "&action_type=\(at)" }
        let response: APIResponse<TemplatesResponse> = try await client.get(path)
        return response.data?.templates ?? []
    }

    // MARK: - Slider
    func getSlider() async throws -> [SliderItem] {
        let path = "/api/v1/slider?app_id=\(appID)&lang=\(lang)"
        let response: APIResponse<SliderResponse> = try await client.get(path)
        return response.data?.slider ?? []
    }

    // MARK: - History
    func getHistory(page: Int = 1, limit: Int = 20) async throws -> [HistoryItem] {
        let path = "/api/v1/history?page=\(page)&limit=\(limit)"
        let response: APIResponse<HistoryResponse> = try await client.get(path)
        return response.data?.history ?? []
    }

    // MARK: - Onboarding
    func getOnboarding() async throws -> [OnboardingMedia] {
        let path = "/api/v1/onboarding?app_id=\(appID)&lang=\(lang)"
        let response: APIResponse<OnboardingResponse> = try await client.get(path)
        return response.data?.onboarding ?? []
    }

    // MARK: - Reviews
    func getReviews() async throws -> [UserReview] {
        let path = "/api/v1/reviews?lang=\(lang)"
        let response: APIResponse<ReviewsResponse> = try await client.get(path)
        return response.data?.reviews ?? []
    }

    // MARK: - Active Providers
    func getProviders() async throws -> [ProviderItem] {
        let response: APIResponse<ProvidersResponse> = try await client.get("/api/v1/providers")
        return response.data?.providers.filter { $0.active } ?? []
    }

    // MARK: - Upload + Transform Pipeline
    func uploadImage(_ image: UIImage, quality: CGFloat = 0.82) async throws -> String {
        guard let data = image.jpegData(compressionQuality: quality) else {
            throw APIError.invalidInput
        }
        let result = try await client.upload(imageData: data)
        return result.url
    }

    func transform(imageURL: String, template: TemplateItem) async throws -> TransformResult {
        let body = TransformRequest(
            provider: template.provider,
            model: template.model,
            imageUrl: imageURL,
            prompt: template.prompt,
            negativePrompt: template.negativePrompt,
            params: nil
        )
        let response: APIResponse<TransformResult> = try await client.post("/api/v1/transform", body: body)
        guard response.success, let data = response.data else {
            throw APIError.serverError(response.error ?? "Transform failed")
        }
        return data
    }

    /// Convenience: upload image and run transform in one call.
    func uploadAndTransform(image: UIImage, template: TemplateItem) async throws -> TransformResult {
        let imageURL = try await uploadImage(image)
        return try await transform(imageURL: imageURL, template: template)
    }
}
