import Foundation

enum LegacyOperationType: String, CaseIterable {
    case Upscaling = "Upscale"
    case Reimagine = "Reimagine"
    case RemoveBackground = "Remove Background"
    case RemoveText = "Remove Text"
    case ReplaceBackground = "Replace Background"
    case SketchToImage = "Sketch To Image"
    case TextToImage = "Text To Image"

    var icon: String {
        switch self {
        case .Upscaling: return "square.resize.up"
        case .Reimagine: return "sparkles.square.filled.on.square"
        case .RemoveBackground: return "person.and.background.striped.horizontal"
        case .RemoveText: return "character.textbox"
        case .ReplaceBackground: return "person.and.background.dotted"
        case .SketchToImage: return "theatermask.and.paintbrush"
        case .TextToImage: return "text.below.photo.fill"
        }
    }
}