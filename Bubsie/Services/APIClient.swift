import Foundation
import UIKit
import os

final class APIClient {
    static let shared = APIClient()
    private let logger = Logger(subsystem: "com.bubsie", category: "API")
    private init() {}

    let baseURL = "https://bubsieapi.kepa.app"

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        return d
    }

    private var currentToken: String? {
        UserDefaults.standard.string(forKey: "bubsie_id_token")
    }

    private var installSeed: String {
        InstallSeedStore.shared.getOrCreate()
    }

    private func makeRequest(method: String, path: String, timeout: TimeInterval = 60) -> URLRequest {
        let url = URL(string: baseURL + path)!
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = timeout
        if let token = currentToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue(installSeed, forHTTPHeaderField: "X-Install-Seed")
        logger.info("GET \(path) | token=\(self.currentToken != nil ? "YES" : "NO") | seed=\(self.installSeed.prefix(8))")
        return req
    }

    func get<T: Decodable>(_ path: String) async throws -> APIResponse<T> {
        let req = makeRequest(method: "GET", path: path)
        let (data, response) = try await URLSession.shared.data(for: req)
        let bodyStr = String(data: data.prefix(500), encoding: .utf8) ?? ""
        logger.info("GET \(path) → \((response as? HTTPURLResponse)?.statusCode ?? 0) | \(bodyStr)")
        try checkHTTPStatus(response, data: data)
        return try decoder.decode(APIResponse<T>.self, from: data)
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B, timeout: TimeInterval = 60) async throws -> APIResponse<T> {
        var req = makeRequest(method: "POST", path: path, timeout: timeout)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTPStatus(response, data: data)
        return try decoder.decode(APIResponse<T>.self, from: data)
    }

    func delete<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> APIResponse<T> {
        var req = makeRequest(method: "DELETE", path: path)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body {
            req.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTPStatus(response, data: data)
        return try decoder.decode(APIResponse<T>.self, from: data)
    }

    func upload(imageData: Data, filename: String = "image.jpg") async throws -> UploadResult {
        var req = makeRequest(method: "POST", path: "/api/v1/upload")
        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let nl = "\r\n"
        body.append("--\(boundary)\(nl)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\(nl)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(nl)\(nl)".data(using: .utf8)!)
        body.append(imageData)
        body.append("\(nl)--\(boundary)--\(nl)".data(using: .utf8)!)
        req.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTPStatus(response, data: data)
        let apiResp = try decoder.decode(APIResponse<UploadResult>.self, from: data)
        guard apiResp.success, let result = apiResp.data else {
            throw APIError.serverError(apiResp.error ?? "Upload failed")
        }
        return result
    }

    private func checkHTTPStatus(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: break
        case 401: throw APIError.unauthorized
        case 402: throw APIError.paymentRequired
        case 403: throw APIError.forbidden
        case 429:
            let retryAfter = Int(http.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw APIError.rateLimited(retryAfter: retryAfter)
        case 502: throw APIError.badGateway
        default:
            if let apiErr = try? decoder.decode(APIResponse<EmptyData>.self, from: data), let msg = apiErr.error {
                throw APIError.serverError(msg)
            }
            throw APIError.serverError("Server error \(http.statusCode)")
        }
    }
}

private struct EmptyData: Decodable {}