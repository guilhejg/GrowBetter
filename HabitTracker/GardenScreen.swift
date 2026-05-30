import SwiftUI

enum GardenPresentationStyle: String, CaseIterable, Identifiable {
    case visual
    case icons
    case assets

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visual: return "Tabuleiro"
        case .icons: return "Ícones"
        case .assets: return "Assets"
        }
    }

    var subtitle: String {
        switch self {
        case .visual: return "Jardim jogável em grid"
        case .icons: return "Jardim funcional em cards"
        case .assets: return "Jardim de cards com imagens"
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
        case .assets:
            FarmGardenView(assetMode: true)
        }
    }
}
