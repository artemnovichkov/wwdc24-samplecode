/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The mock data and request related to payment passes.
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
    var isAvailableForProvisioning: Bool
    var cardholderName: String
    var localizedDescription: String
    var primaryAccountSuffix: String
    var expiration: String
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
