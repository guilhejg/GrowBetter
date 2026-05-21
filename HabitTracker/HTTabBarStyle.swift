// HTTabBarStyle.swift
import UIKit

enum HTTabBarStyle {

    static func makeTransparent() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        // ✅ remove qualquer cor “de sistema”
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        // iOS 15+ precisa setar os DOIS
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // ✅ reforço extra
        UITabBar.appearance().isTranslucent = true
    }
}
