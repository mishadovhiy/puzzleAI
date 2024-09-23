
import Foundation
import Security

enum KeychainKey: String, CaseIterable {
    case balance = "balanceValue3"
}

struct KeychainService {
    static private var appGroupName:String {
        return Keys.appGroup.rawValue
    }
    
    static func saveToken(_ token: String, forKey key: KeychainKey, canSaveToError:Bool = true) -> Bool {
        guard let data = token.data(using: .utf8) else { return true }
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.key,
            kSecValueData as String: data,
            kSecAttrSynchronizable as String: kCFBooleanTrue ?? true,
            kSecAttrAccessGroup as String: appGroupName
        ] as [String : Any]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error Saving Token To Key Chain")
            if canSaveToError {
                DB.db.errorTokenValue = token
            }
            return false
        } else {
            if canSaveToError && DB.db.errorTokenValue != "" {
                if self.saveToken(DB.db.errorTokenValue,
                                  forKey: key, canSaveToError: false) {
                    DB.db.errorTokenValue = ""
                }
            }
            print("Token Saved with status \(status)")
            return true
        }
    }
    
    static func getToken(forKey key: KeychainKey) -> String? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrSynchronizable as String: kCFBooleanTrue ?? true,
            kSecAttrAccessGroup as String: appGroupName
        ] as [String : Any]
        
        var tokenData: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &tokenData)
        if status == errSecSuccess, let data = tokenData as? Data {
            return String(data: data, encoding: .utf8)
        }
#if DEBUG
        print("Error Retrieving Token from Key Chain ", key)
#endif
        return nil
    }
}

extension KeychainKey {
    var key:String {
        (Bundle.main.bundleIdentifier ?? "") + "." + rawValue
    }
}
