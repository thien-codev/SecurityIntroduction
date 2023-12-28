//
//  ViewController.swift
//  iOSAppSecurityIntroduction
//
//  Created by ndthien01 on 26/12/2023.
//

import UIKit
import HealthKit
import LocalAuthentication

enum PermissionError: Error {
    case stepDataReadError
}

enum LocalAuthenticationError: Error {
    case biometryNotAvailable
    case forwarded(Error)
    case unknown
}

class ViewController: UIViewController {
    
    @IBOutlet private weak var username: UITextField!
    @IBOutlet private weak var password: UITextField!
    @IBOutlet private weak var confirmPassword: UITextField!
    @IBOutlet private weak var textView: UITextView!
    
    lazy var keychainFacade = KeychainFacade()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Pasteboard storage
        textView.text = AppDelegate.customPasteboard?.string
        
        if HKHealthStore.isHealthDataAvailable() {
            requestPermission { [weak self] success, error in
                if success {
                    self?.queryTodaysSteps { print("aaa \($0)") }
                } else {
                    print(error ?? "Unknown error")
                }
            }
        }
        
        // data protection
        let text = "Super secret text"
        if let fileUrl = try? FileManager.default.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false).appendingPathExtension("protectedData.txt") {
            if secureSave(value: text, to: fileUrl) {
                print("Save success at \(fileUrl)")
            } else {
                print("Save failure")
            }
        }
        
        // Biometric
        setupBiometric()
        
        // Asymmetric cryptographic
        testAsymmetricCryptoGraphic()
    }
}

// MARK: - Keychains
extension ViewController {
    @IBAction private func save(_ sender: Any) {
        guard let username = username.text,
              let password = password.text else { return }
        do {
            try keychainFacade.set(username, forKey: "username")
            try keychainFacade.set(password, forKey: "password")
            
            let storedUsername = try keychainFacade.string(forKey: "username")
            let storedPassword = try keychainFacade.string(forKey: "password")
            
            print("Username: \(String(describing: storedUsername))")
            print("Password: \(String(describing: storedPassword))")
        } catch let facadeError as KeychainFacadeError {
            print("Could not store credentials in the keychain. \(facadeError)")
        } catch {
            print(error)
        }
    }
    
    @IBAction private func clearCache(_ sender: Any) {
        do {
            try keychainFacade.remove(forKey: "username")
            try keychainFacade.remove(forKey: "password")
        } catch let facadeError as KeychainFacadeError {
            print("Could not remove credentials in the keychain. \(facadeError)")
        } catch {
            print(error)
        }
    }
}

// MARK: - HealthKit
extension ViewController {
    private func requestPermission(completion: @escaping (Bool, Error?) -> Void) {
        guard let stepQuantityType = HKObjectType.quantityType(forIdentifier: .walkingStepLength) else {
            completion(false, PermissionError.stepDataReadError)
            return
        }
        
        let types = Set([stepQuantityType])
        
        let healthStore = HKHealthStore()
        healthStore.requestAuthorization(toShare: nil, read: types, completion: completion)
    }
    
    private func queryTodaysSteps(completion: @escaping (Double) -> Void) {
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: today, options: .strictStartDate)

        guard let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: HKStatisticsOptions.cumulativeSum) { (statsQuery, result, error) in
            if let queryError = error {
                print(queryError)
                completion(0)
                return
            }
            
            guard let steps = result?.sumQuantity() else {
                completion(0)
                return
            }
            completion(steps.doubleValue(for: HKUnit.count()))
        }
        
        let healthStore = HKHealthStore()
        healthStore.execute(query)
    }
}

// MARK: - Data protection
extension ViewController {
    func secureSave(value: String, to fileUrl: URL) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("Invalid value")
            return false
        }
        do {
            try data.write(to: fileUrl, options: [.completeFileProtectionUnlessOpen])
        } catch {
            print(error, fileUrl)
            return false
        }
        return true
    }
}

// MARK: - Biometric authentication
extension ViewController {
    func setupBiometric() {
        let authenticationContext = LAContext()
        var localAuthenticationError: NSError?
        
        if authenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &localAuthenticationError) {
            print("The device has supported biometric authentication")
            
            var reason: String = ""
            
            switch authenticationContext.biometryType {
            case .touchID:
                reason = "Log in with your Touch ID"
            case .faceID:
                reason = "Log in with your Face ID"
            default: break
            }
            
            
            authenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
                let title = success ? "Success" : "Failure"
                let message = success ? "You logged in to continue" : "You logged in failure \(String(describing: error?.localizedDescription))"
                
                DispatchQueue.main.async(execute: {
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    let comfirmAction = UIAlertAction(title: "Ok", style: .cancel)
                    alert.addAction(comfirmAction)
                    
                    self.present(alert, animated: true)
                })
                
            }
        } else {
            print("The device hasn't supported biometric authentication with \(String(describing: localAuthenticationError))")
        }
    }
}

// MARK: - Public key vs Private key
extension ViewController {
    func testAsymmetricCryptoGraphic() {
        let text = "The sensitive infomations"
        
        do {
            guard let encryptedData = try keychainFacade.encrypt(string: text) else {
                print("Can not encrypt data")
                return
            }
            
            guard let decryptedData = try keychainFacade.decrypt(data: encryptedData) else {
                print("Can not decrypt data")
                return
            }
            print("Success  --->  \(String(data: decryptedData, encoding: .utf8) ?? "")")
        } catch {
            print("\(#function) return error: \(error)")
        }
    }
}

