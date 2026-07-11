import Foundation
import UIKit

struct BabyUltraAPI {
    static let shared = BabyUltraAPI()
    private init() {}

    private let client = APIClient.shared
    private let appID = "babyultra"

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

    func activatePro() async throws {
        let response: APIResponse<EmptyData> = try await client.post("/api/v1/me/pro", body: EmptyRequest())
        guard response.success else {
            throw APIError.serverError(response.error ?? "Failed to activate pro")
        }
    }

    func syncPurchases() async throws {
        let response: APIResponse<EmptyData> = try await client.post("/api/v1/sync-purchases", body: EmptyRequest())
        guard response.success else {
            throw APIError.serverError(response.error ?? "Failed to sync purchases")
        }
    }

    func deleteAccount() async throws {
        let response: APIResponse<EmptyData> = try await client.post("/api/v1/me/delete", body: EmptyRequest())
        guard response.success else {
            throw APIError.serverError(response.error ?? "Failed to delete account")
        }
    }

    // MARK: - Categories
    func getCategories(type: String? = nil) async throws -> [CategoryItem] {
        var path = "/api/v1/categories?app_id=\(appID)&lang=\(lang)"
        if let t = type { path += "&type=\(t)" }
        let response: APIResponse<CategoriesResponse> = try await client.get(path)
        return response.data?.categories ?? []
    }

    // MARK: - Templates
    func getTemplates(categoryID: Int? = nil, featured: Bool? = nil, popular: Bool? = nil, viral: Bool? = nil, type: String? = nil, actionType: String? = nil, includeHidden: Bool = false) async throws -> [TemplateItem] {
        var path = "/api/v1/templates?app_id=\(appID)&lang=\(lang)"
        if let id = categoryID { path += "&category_id=\(id)" }
        if let f = featured { path += "&featured=\(f)" }
        if let p = popular { path += "&popular=\(p)" }
        if let v = viral { path += "&viral=\(v)" }
        if let t = type { path += "&type=\(t)" }
        if let at = actionType { path += "&action_type=\(at)" }
        if includeHidden { path += "&include_hidden=true" }
        let response: APIResponse<TemplatesResponse> = try await client.get(path)
        return response.data?.templates ?? []
    }

    // MARK: - Slider
    func getSlider(type: String? = nil) async throws -> [SliderItem] {
        var path = "/api/v1/slider?app_id=\(appID)&lang=\(lang)"
        if let t = type { path += "&type=\(t)" }
        let response: APIResponse<SliderResponse> = try await client.get(path)
        return response.data?.slider ?? []
    }

    // MARK: - Quick Buttons
    func getQuickButtons(type: String = "photo") async throws -> [QuickButtonItem] {
        let path = "/api/v1/quick-buttons?app_id=\(appID)&type=\(type)"
        let response: APIResponse<QuickButtonsResponse> = try await client.get(path)
        return response.data?.buttons ?? []
    }

    // MARK: - History
    func getHistory(page: Int = 1, limit: Int = 20) async throws -> [HistoryItem] {
        let path = "/api/v1/history?page=\(page)&limit=\(limit)"
        let response: APIResponse<HistoryResponse> = try await client.get(path)
        return response.data?.history ?? []
    }

    func deleteHistoryItem(id: Int) async throws {
        do {
            let response: APIResponse<EmptyData> = try await client.delete("/api/v1/history/\(id)")
            guard response.success else {
                throw APIError.serverError(response.error ?? "Failed to delete history item")
            }
        } catch {
            // Fallback for environments where DELETE may be blocked by proxy/CDN rules
            let response: APIResponse<EmptyData> = try await client.post("/api/v1/history/\(id)/delete", body: EmptyRequest())
            guard response.success else {
                throw APIError.serverError(response.error ?? "Failed to delete history item")
            }
        }
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

    // MARK: - Languages
    func getLanguages() async throws -> [LanguageItem] {
        let response: APIResponse<LanguagesResponse> = try await client.get("/api/v1/languages")
        return response.data?.languages ?? []
    }

    // MARK: - Upload
    func uploadImage(_ image: UIImage, quality: CGFloat = 0.82) async throws -> String {
        let normalizedImage = image.normalizedOrientation()
        guard let data = normalizedImage.jpegData(compressionQuality: quality) else {
            throw APIError.invalidInput
        }
        let result = try await client.upload(imageData: data)
        return result.url
    }

    // MARK: - Transform
    func transform(imageURL: String, template: TemplateItem, aspectRatio: String? = nil, momImageURL: String? = nil, babyImageURL: String? = nil, dadImageURL: String? = nil, imageUrls: [String]? = nil, videoURL: String? = nil, notifyWhenDone: Bool = false) async throws -> TransformResult {
        var paramsDict: [String: String]? = nil
        if let ar = aspectRatio {
            paramsDict = ["aspect_ratio": ar]
        }

        let body = TransformRequest(
            provider: template.provider,
            model: template.model,
            imageUrl: imageURL,
            imageUrls: imageUrls,
            momImageUrl: momImageURL,
            babyImageUrl: babyImageURL,
            dadImageUrl: dadImageURL,
            prompt: template.prompt,
            negativePrompt: template.negativePrompt,
            params: paramsDict,
            creditCost: template.creditCost,
            notifyWhenDone: notifyWhenDone
        )
        let timeout: TimeInterval = template.actionType == "video" ? 300 : 120
        let response: APIResponse<TransformResult> = try await client.post("/api/v1/transform", body: body, timeout: timeout)
        guard response.success, let data = response.data else {
            throw APIError.serverError(response.error ?? "Transform failed")
        }
        return data
    }

    // MARK: - Upload + Transform Pipeline
    func uploadAndTransform(image: UIImage, template: TemplateItem, aspectRatio: String? = nil, momImageURL: String? = nil, babyImageURL: String? = nil, dadImageURL: String? = nil, imageUrls: [String]? = nil, videoURL: String? = nil, notifyWhenDone: Bool = false, image2: UIImage? = nil) async throws -> TransformResult {
        let imageURL = try await uploadImage(image)
        var secondImageURL: String? = nil
        if let img2 = image2 {
            secondImageURL = try await uploadImage(img2)
        }
        
        var finalMomImageURL = momImageURL
        var finalDadImageURL = dadImageURL
        var finalImageURL = imageURL
        var finalImageUrls = imageUrls
        
        if template.requireMomPhoto == true && template.requireDadPhoto == true {
            finalMomImageURL = imageURL
            finalDadImageURL = secondImageURL
            finalImageURL = "" // Ensure backend logic correctly parses Mom & Dad
            
            if let secondImg = secondImageURL {
                finalImageUrls = [imageURL, secondImg]
            }
        }
        
        return try await transform(
            imageURL: finalImageURL,
            template: template,
            aspectRatio: aspectRatio,
            momImageURL: finalMomImageURL,
            babyImageURL: babyImageURL,
            dadImageURL: finalDadImageURL,
            imageUrls: finalImageUrls,
            videoURL: videoURL,
            notifyWhenDone: notifyWhenDone
        )
    }

    // MARK: - Device Token
    func registerDeviceToken(_ token: String, platform: String = "ios") async throws {
        let body = DeviceTokenRequest(
            token: token,
            platform: platform,
            appId: appID,
            locale: lang
        )
        _ = try await client.post("/api/v1/device-token", body: body) as APIResponse<EmptyData>
    }

    func deleteDeviceToken(_ token: String) async throws {
        struct TokenBody: Encodable { let token: String }
        _ = try await client.delete("/api/v1/device-token", body: TokenBody(token: token)) as APIResponse<EmptyData>
    }

    // MARK: - Chat
    func sendChatMessage(_ message: String) async throws -> String {
        struct ChatRequest: Encodable {
            let message: String
        }
        struct ChatResponse: Decodable {
            let reply: String
        }
        let body = ChatRequest(message: message)
        let response: APIResponse<ChatResponse> = try await client.post("/api/v1/chat", body: body, timeout: 120)
        guard response.success, let data = response.data else {
            throw APIError.serverError(response.error ?? "Chat failed")
        }
        return data.reply
    }

    // MARK: - Firebase Config
    func getFirebaseConfig() async throws -> FirebaseConfig {
        let response: APIResponse<FirebaseConfig> = try await client.get("/api/config/firebase")
        guard response.success, let data = response.data else {
            throw APIError.serverError(response.error ?? "Failed to load Firebase config")
        }
        return data
    }

    // MARK: - Report
    func submitReport(resultURL: String, reason: String, details: String? = nil) async throws {
        let body = CreateReportRequest(
            resultUrl: resultURL,
            reason: reason,
            details: details
        )
        let response: APIResponse<SubmitReportResponse> = try await client.post("/api/v1/reports", body: body)
        guard response.success else {
            throw APIError.serverError(response.error ?? "Failed to submit report")
        }
    }
}

private struct EmptyData: Decodable {}
private struct EmptyRequest: Encodable {}
