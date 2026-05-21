import UIKit

enum HTAppearance {

    static func configureTabBarTransparent() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        UITabBar.appearance().standardAppearance = appearance

        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
