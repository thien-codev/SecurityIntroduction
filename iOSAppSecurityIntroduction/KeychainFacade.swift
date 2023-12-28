//
//  KeychainFacade.swift
//  iOSAppSecurityIntroduction
//
//  Created by ndthien01 on 26/12/2023.
//

import Foundation
import Security

public enum KeychainFacadeError: Error {
    case invalidContent
    case failure(status: OSStatus)
    case keyGenerationError
    case noPublicKey
    case noPrivateKey
    case unsupported(algorithm: SecKeyAlgorithm)
    case forwarded(Error)
    case unknown
}

class KeychainFacade {
    
    private func setupQueryDictionary(for key: String) -> [String: Any] {
        var queryDictionary: [String: Any] = [kSecClass as String: kSecClassGenericPassword]
        queryDictionary[kSecAttrAccount as String] = key.data(using: .utf8)
        return queryDictionary
    }
    
    public func set(_ value: String, forKey key: String) throws {
        guard !value.isEmpty && !key.isEmpty else {
            print("Can't add an empty string to the keychain")
            throw KeychainFacadeError.invalidContent
        }
        
        var queryDic = setupQueryDictionary(for: key)
        queryDic[kSecValueData as String] = value.data(using: .utf8)
        
        let status = SecItemAdd(queryDic as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw KeychainFacadeError.failure(status: status)
        }
    }
    
    public func remove(forKey key: String) throws {
        guard !key.isEmpty else {
            print("Can't remove an empty string to the keychain")
            throw KeychainFacadeError.invalidContent
        }
        
        let queryDic = setupQueryDictionary(for: key)
        let status = SecItemDelete(queryDic as CFDictionary)
        
        if status != errSecSuccess {
            throw KeychainFacadeError.failure(status: status)
        }
    }
    
    public func string(forKey key: String) throws -> String? {
        guard !key.isEmpty else {
            print("Can't retrieve an empty string to the keychain")
            throw KeychainFacadeError.invalidContent
        }
        
        var queryDic = setupQueryDictionary(for: key)
        queryDic[kSecReturnData as String] = kCFBooleanTrue
        queryDic[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var data: AnyObject?
        let status = SecItemCopyMatching(queryDic as CFDictionary, &data)
        
        if status != errSecSuccess {
            throw KeychainFacadeError.failure(status: status)
        }
        
        var result: String?
        if let dataResult = data as? Data {
            result = String(data: dataResult, encoding: .utf8)
        }
        
        return result
    }
    
    private var keyAttribute: [String: Any] = [kSecAttrType as String: kSecAttrKeyTypeRSA,
                                               kSecAttrKeySizeInBits as String: 2048,
                                               kSecAttrApplicationTag as String: tagData,
                                               kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: true]]
    
    lazy var privateKey: SecKey? = {
        guard let key = try? retrievePrivateKey()else {
            return try? generatePrivateKey()
        }
        
        return key
    }()
    
    lazy var publicKey: SecKey? = {
        guard let privateKey else {
            return nil
        }
        
        return SecKeyCopyPublicKey(privateKey)
    }()
}

// MARK: - Private key
extension KeychainFacade {
    private static var tagData = "com.iOSAppSecurityIntroduction.keys.mykey".data(using: .utf8)!
    
    func generatePrivateKey() throws -> SecKey {
        guard let privateKey = SecKeyCreateRandomKey(keyAttribute as CFDictionary, nil) else {
            throw KeychainFacadeError.keyGenerationError
        }
        return privateKey
    }
    
    func retrievePrivateKey() throws -> SecKey? {
        let privateKey: [String: Any] = [kSecClass as String: kSecClassKey,
                                         kSecAttrApplicationTag as String: KeychainFacade.tagData,
                                         kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                         kSecReturnRef as String: true]
        
        var privateKeyRef: CFTypeRef?
        let status = SecItemCopyMatching(privateKey as CFDictionary, &privateKeyRef)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            } else {
                throw KeychainFacadeError.failure(status: status)
            }
        }
        
        return privateKeyRef != nil ? (privateKeyRef as! SecKey) : nil
    }
    
    func encrypt(string: String) throws -> Data? {
        guard let publicKey else {
            throw KeychainFacadeError.noPublicKey
        }
        
        let algorithm = SecKeyAlgorithm.rsaEncryptionOAEPSHA512
        
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw KeychainFacadeError.unsupported(algorithm: algorithm)
        }
        
        guard let textData = string.data(using: .utf8) else {
            throw KeychainFacadeError.invalidContent
        }
        
        var error: Unmanaged<CFError>?
        guard let encryptedText = SecKeyCreateEncryptedData(publicKey, algorithm, textData as CFData, &error) as? Data else {
            if let error {
                throw KeychainFacadeError.forwarded(error.takeRetainedValue() as Error)
            } else {
                throw KeychainFacadeError.unknown
            }
        }
        
        return encryptedText
    }
    
    func decrypt(data: Data) throws -> Data? {
        guard let privateKey else {
            throw KeychainFacadeError.noPrivateKey
        }
        
        let algorithm = SecKeyAlgorithm.rsaEncryptionOAEPSHA512
        
        guard SecKeyIsAlgorithmSupported(privateKey, .encrypt, algorithm) else {
            throw KeychainFacadeError.unsupported(algorithm: algorithm)
        }
        
        var error: Unmanaged<CFError>?
        
        guard let data = SecKeyCreateDecryptedData(privateKey, algorithm, data as CFData, &error) as? Data else {
            if let error {
                throw KeychainFacadeError.forwarded(error.takeRetainedValue() as Error)
            } else {
                throw KeychainFacadeError.unknown
            }
        }
        
        return data
    }
}

