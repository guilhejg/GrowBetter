import Combine
import Foundation
import UIKit

enum HTAccountSession {
    static let isSignedInKey = "account.isSignedIn"
    static let providerKey = "account.provider"
    static let appleUserIDKey = "account.apple.userID"
    static let displayNameKey = "account.displayName"
    static let emailKey = "account.email"

    static var isSignedIn: Bool {
        UserDefaults.standard.bool(forKey: isSignedInKey)
    }

    static var displayName: String? {
        UserDefaults.standard.string(forKey: displayNameKey)
    }

    static var email: String? {
        UserDefaults.standard.string(forKey: emailKey)
    }

    static func saveGuestName(_ name: String) {
        let formattedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        saveLocalSession(name: formattedName.isEmpty ? "Convidado" : formattedName)
    }

    static func saveLocalSession(name: String) {
        let formattedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: isSignedInKey)
        defaults.set("local", forKey: providerKey)
        defaults.set(formattedName.isEmpty ? "Convidado" : formattedName, forKey: displayNameKey)
        defaults.removeObject(forKey: appleUserIDKey)
        defaults.removeObject(forKey: emailKey)
    }

    static func signOut() {
        let defaults = UserDefaults.standard
        [
            isSignedInKey,
            providerKey,
            appleUserIDKey,
            displayNameKey,
            emailKey
        ].forEach { defaults.removeObject(forKey: $0) }
    }
}
