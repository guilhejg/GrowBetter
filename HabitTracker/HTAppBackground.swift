import SwiftUI

struct HTAppBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.01, green: 0.03, blue: 0.035)
                .ignoresSafeArea()

            Image("app_bg")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        }
    }
}
