import Foundation
import SwiftUI

// MARK: - App Constants
struct Constants {
    // Replace with your actual Clipdrop / Fal.ai / Replicate API key
    let API_KEY = "36d77dca241164279196c7248e5e915080cd94fd43e16b3fc1f2d570c41994f5396f616743230876d341febab11c20da"
}

// MARK: - Credit System
// 8 credits are given on first install (managed by CoinCounter via AppStorage).
// Each AI operation costs 1 credit. Premium users bypass credit checks.

// MARK: - AI Backend Placeholders
// These structs represent the response shape expected from Fal.ai / Replicate.
struct AIJobResponse: Decodable {
    let id: String
    let status: String      // "IN_QUEUE" | "IN_PROGRESS" | "COMPLETED" | "FAILED"
    let result_url: String?
}

enum AIJobStatus: String {
    case idle       = "IDLE"
    case uploading  = "UPLOADING"
    case processing = "IN_PROGRESS"
    case completed  = "COMPLETED"
    case failed     = "FAILED"
}
