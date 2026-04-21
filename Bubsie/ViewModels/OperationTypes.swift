import Foundation
import SwiftUI

enum ActionType: String, CaseIterable {
    case imageGeneration = "image_generation"
    case aiChat = "ai_chat"
    case upscale = "upscale"
    case removeBg = "remove_bg"
    case photoRestoration = "photo_restoration"

    var displayName: String {
        switch self {
        case .imageGeneration: return "Image Generation"
        case .aiChat: return "BubsieAI"
        case .upscale: return "Upscale"
        case .removeBg: return "Remove BG"
        case .photoRestoration: return "Photo Restore"
        }
    }

    var icon: String {
        switch self {
        case .imageGeneration: return "wand.and.sparkles"
        case .aiChat: return "bubble.left.and.bubble.right.fill"
        case .upscale: return "square.resize.up"
        case .removeBg: return "person.and.background.striped.horizontal"
        case .photoRestoration: return "photo.badge.plus"
        }
    }
}
