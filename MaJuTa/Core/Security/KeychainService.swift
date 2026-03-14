import Foundation
import Security

enum KeychainService {

    @discardableResult
    static func set(_ value: Double, for key: String) -> Bool {
        var bytes = value
        let data = Data(bytes: &bytes, count: MemoryLayout<Double>.size)
        return set(data, for: key)
    }

    static func getDouble(for key: String) -> Double? {
        guard let data = getData(for: key),
              data.count == MemoryLayout<Double>.size else { return nil }
        return data.withUnsafeBytes { $0.load(as: Double.self) }
    }

    @discardableResult
    static func set(_ value: String, for key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return set(data, for: key)
    }

    static func getString(for key: String) -> String? {
        guard let data = getData(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func set(_ data: Data, for key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecAttrAccessible:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let attributes: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecAttrAccessible:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData:        data
        ]
        return SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess
    }

    static func getData(for key: String) -> Data? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    @discardableResult
    static func delete(for key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
