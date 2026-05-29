import SwiftUI

enum GardenPresentationStyle: String, CaseIterable, Identifiable {
    case visual
    case icons

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visual: return "Visual"
        case .icons: return "Ícones"
        }
    }

    var subtitle: String {
        switch self {
        case .visual: return "Jardim ilustrado com assets"
        case .icons: return "Jardim funcional em cards"
        }
    }
}

struct GardenScreen: View {
    @AppStorage("garden.presentationStyle") private var presentationStyle: GardenPresentationStyle = .visual

    var body: some View {
        switch presentationStyle {
        case .visual:
            VisualGardenView()
        case .icons:
            FarmGardenView()
        }
    }
}
