import Foundation
import Security

struct KeychainManager {
    private static let tokenKey = "com.stacknest.jelly.token"
    private static let userIdKey = "com.stacknest.jelly.userId"
    private static let usernameKey = "com.stacknest.jelly.username"

    static func save(token: String, userId: String, username: String) {
        set(token, forKey: tokenKey)
        set(userId, forKey: userIdKey)
        set(username, forKey: usernameKey)
    }

    static func loadToken() -> String? { get(forKey: tokenKey) }
    static func loadUserId() -> String? { get(forKey: userIdKey) }
    static func loadUsername() -> String? { get(forKey: usernameKey) }

    static func clear() {
        delete(forKey: tokenKey)
        delete(forKey: userIdKey)
        delete(forKey: usernameKey)
    }

    private static func set(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func get(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
