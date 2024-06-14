/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The mock structures and classes that support the tests.
*/

import os
import PassKit

let log = Logger()

/**
 This structure mocks the data that the user's defaults database can store to support the code
 in the non-UI extension. Refactor this structure to support the issuer app's persisted
 payment card data.
 */
struct ProvisioningCredential: Equatable, Codable, Hashable {
    var primaryAccountIdentifier: String
    var label: String
    var assetName: String
    var cardholderName: String
    var localizedDescription: String
    var primaryAccountSuffix: String
    var expiration: String
}

/**
 This structure mocks retrieving required data for a payment pass to support the sample code in the
 non-UI extension's principal class. Refactor this structure to support retrieving the
 necessary pass data from the issuer's server.
 */
struct PassResource {
    
    static public func requestPaymentPassData(_ configuration: PKAddPaymentPassRequestConfiguration, certificateChain certificates: [Data],
                                              nonce: Data, nonceSignature: Data) -> EncryptedPassDataResponse {
        
        var response = EncryptedPassDataResponse()
        response.activationData = Data()
        response.encryptedPassData = Data()
        
        if configuration.encryptionScheme == .ECC_V2 {
            response.ephemeralPublicKey = Data()
        } else if configuration.encryptionScheme == .RSA_V2 {
            response.wrappedKey = Data()
        }
        
        return response
    }
}

/**
 This structure mocks a response object for encrypted pass data to support the sample code
 in the non-UI extension.
 */
struct EncryptedPassDataResponse {
    var activationData: Data?
    var encryptedPassData: Data?
    var ephemeralPublicKey: Data?
    var wrappedKey: Data?
}

/**
 This class mocks `UserDefaults` to support testing the non-UI extension.
 */
class MockUserDefaults: UserDefaults {
    private var passCredentialsData: [String: ProvisioningCredential] = [:]
    
    override func data(forKey defaultName: String) -> Data? {
        if defaultName == "PaymentPassCredentials" && !passCredentialsData.isEmpty {
            if let encoded = try? JSONEncoder().encode(passCredentialsData) {
                return encoded
            }
        }
        return nil
    }
    
    override func bool(forKey defaultName: String) -> Bool {
        if defaultName == "ShouldRequireAuthenticationForAppleWallet" {
            return true
        }
        return false
    }
    
    func addPassCredentialJson(_ primaryAccountIdentifier: String, cardholderName: String,
                               primaryAccountSuffix: String, expiration: String) {
        
        let credential = ProvisioningCredential(primaryAccountIdentifier: primaryAccountIdentifier,
                                                label: "",
                                                assetName: "",
                                                cardholderName: cardholderName,
                                                localizedDescription: "",
                                                primaryAccountSuffix: primaryAccountSuffix,
                                                expiration: expiration)
        
        passCredentialsData[primaryAccountIdentifier] = credential
    }
}

/**
 This class mocks `PKPassLibrary` to support testing the non-UI extension.
 */
class MockPKPassLibrary: PKPassLibrary {
    var mockPasses: [PKPass] = []
    
    override func passes(of passType: PKPassType) -> [PKPass] {
        if passType == .secureElement {
            return mockPasses
        }
        return []
    }
}

/**
 This class mocks `PKPass` to support testing the non-UI extension.
 */
class MockPKPass: PKPass {
    var primaryAccountIdentifier: String = ""
    var isRemote: Bool = false
    
    init(primaryAccountIdentifier: String, isRemote: Bool) {
        super.init()
        self.primaryAccountIdentifier = primaryAccountIdentifier
        self.isRemote = isRemote
    }
    
    override var passType: PKPassType { .secureElement }
    
    override var deviceName: String {
        if isRemote {
            return "Apple Watch"
        } else {
            return "iPhone"
        }
    }
    
    override var isRemotePass: Bool { isRemote }
    
    override var secureElementPass: PKSecureElementPass? {
        let pass = MockPKSecureElementPass()
        pass.primaryAccountIdentifierOverride = primaryAccountIdentifier
        return pass
    }
}

/**
 This class mocks `PKSecureElementPass` to support testing the non-UI extension.
 */
class MockPKSecureElementPass: PKSecureElementPass {
    var primaryAccountIdentifierOverride = ""
    
    override var primaryAccountIdentifier: String { primaryAccountIdentifierOverride }
}

/**
 This class mocks `WatchConnectivitySession` to support testing the non-UI extension.
 */
class MockWatchConnectivitySession: WatchConnectivitySession {
    var paired: Bool
    
    init(paired: Bool = true) {
        self.paired = paired
    }
    
    override var isPaired: Bool { paired }
}

/**
 Extends `PKIssuerProvisioningExtensionStatus` to support testing the non-UI extension.
 */
extension PKIssuerProvisioningExtensionStatus {
    
    override open func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? PKIssuerProvisioningExtensionStatus else {
            return false
        }
        
        let lhs = self
        return lhs.passEntriesAvailable == rhs.passEntriesAvailable &&
            lhs.remotePassEntriesAvailable == rhs.remotePassEntriesAvailable &&
            lhs.requiresAuthentication == rhs.requiresAuthentication
    }
}

