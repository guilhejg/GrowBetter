import SwiftUI

struct StatsView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Stats")
                .foregroundStyle(.white.opacity(0.8))
                .font(.system(size: 18, weight: .semibold))
        }
    }
}
