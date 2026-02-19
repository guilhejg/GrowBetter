import SwiftUI

struct GardenScreen: View {
    private let world = GardenWorld.generate500()

    var body: some View {
        GardenMapView(world: world)
    }
}
