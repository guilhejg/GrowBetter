import Foundation
import SwiftData

struct AgaBloomProgress {

    static func level(for totalCompletions: Int) -> Int {
        switch totalCompletions {
        case 0..<1: return 0
        case 1..<2: return 1
        case 2..<3: return 2
        case 3..<4: return 3
        case 4..<5: return 4
        default: return 5
        }
    }

    static func imageName(for level: Int) -> String {
        switch level {
        case 0: return "agabloom_seed"
        case 1: return "agabloom_sprout"
        case 2: return "agabloom_small"
        case 3: return "agabloom_medium"
        case 4: return "agabloom_big"
        default: return "agabloom_bloom"
        }
    }
}
