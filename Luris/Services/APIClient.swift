import Foundation
import UIKit

final class APIClient {
    static let shared = APIClient()
    private init() {}

    let baseURL = "https://aibackend.kepa.app"

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        return d
    }

    // MARK: - Authorized Request Builder
    // Read token directly from UserDefaults — nonisolated and thread-safe.
    // AuthManager writes to the same key, so this stays in sync automatically.
    private var currentToken: String? {
        UserDefaults.standard.string(forKey: "luris_id_token")
    }

    private func makeRequest(method: String, path: String) -> URLRequest {
        let url = URL(string: baseURL + path)!
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.timeoutInterval = 60
        if let token = currentToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    // MARK: - GET
    func get<T: Decodable>(_ path: String) async throws -> APIResponse<T> {
        let req = makeRequest(method: "GET", path: path)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTPStatus(response, data: data)
        return try decoder.decode(APIResponse<T>.self, from: data)
    }

    // MARK: - POST JSON
    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> APIResponse<T> {
        var req = makeRequest(method: "POST", path: path)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkHTTPStatus(response, data: data)
        return try decoder.decode(APIResponse<T>.self, from: data)
    }

    // MARK: - Multipart Upload
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

    // MARK: - HTTP Status Checker
    private func checkHTTPStatus(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: break
        case 401: throw APIError.unauthorized
        case 429:
            let retryAfter = Int(http.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw APIError.rateLimited(retryAfter: retryAfter)
        default:
            if let apiErr = try? decoder.decode(APIResponse<EmptyData>.self, from: data), let msg = apiErr.error {
                throw APIError.serverError(msg)
            }
            throw APIError.serverError("Server error \(http.statusCode)")
        }
    }
}

private struct EmptyData: Decodable {}
