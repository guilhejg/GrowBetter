import Foundation

enum AgaBloomStage: Int, CaseIterable {
    case seed
    case sprout
    case smallBloom
    case fullBloom

    var assetName: String {
        switch self {
        case .seed: return "agabloom_seed"
        case .sprout: return "agabloom_sprout"
        case .smallBloom: return "agabloom_small"
        case .fullBloom: return "agabloom_full"
        }
    }

    var fallbackSymbol: String {
        switch self {
        case .seed: return "circle.fill"
        case .sprout: return "leaf.fill"
        case .smallBloom: return "camera.macro"
        case .fullBloom: return "sparkles"
        }
    }
}

enum AgaBloomEngine {
    static func stage(totalUniqueDays: Int) -> AgaBloomStage {
        switch totalUniqueDays {
        case 0...3: return .seed
        case 4...10: return .sprout
        case 11...25: return .smallBloom
        default: return .fullBloom
        }
    }
}
