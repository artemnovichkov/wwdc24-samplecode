/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A non-UI extension that reports on the status and gets passes available to add to Apple Wallet.
*/

import PassKit

/**
 The non-UI extension's principal class.
 */
class WNonUIExtHandler: PKIssuerProvisioningExtensionHandler {
    let passLibrary = PKPassLibrary()
    let watchSession = WatchConnectivitySession()

    /**
     Set the status of the extension to indicate whether a payment pass is available to add and whether
     adding it requires authentication.
     */
    override func status(completion: @escaping (PKIssuerProvisioningExtensionStatus) -> Void) {
        
        // Pass this status to the completion handler.

        let status = PKIssuerProvisioningExtensionStatus()
        var paymentPassLibrary: [PKPass] = []
        var passIdentifiers: Set<String> = []
        var remotePassIdentifiers: Set<String> = []
        var availablePassesForIphone: Int = 0
        var availableRemotePassesForAppleWatch: Int = 0
        
        // Get the identifiers of payment passes that already exist in Apple Pay.
        paymentPassLibrary = self.passLibrary.passes(of: .secureElement)
        
        for pass in paymentPassLibrary {
            if let identifier = pass.secureElementPass?.primaryAccountIdentifier {
                if pass.isRemotePass && pass.deviceName.localizedCaseInsensitiveContains("Apple Watch") {
                    remotePassIdentifiers.insert(identifier)
                } else if !pass.isRemotePass {
                    passIdentifiers.insert(identifier)
                }
            }
        }
        
        // Get cached credential data of all of the user's issued cards,
        // within the issuer app, from the user's defaults database.
        if let cachedCredentialsData = appGroupSharedDefaults.data(forKey: "PaymentPassCredentials") {
            
            // Decodes the cached credential data of all of the user's
            // issued cards.
            // Note: `ProvisioningCredential` is not a member of PassKit.
            // Modify this logic based on how the issuer app
            // structures persisted data of an issued card.
            if let decoded = try? JSONDecoder().decode([String: ProvisioningCredential].self, from: cachedCredentialsData) {
                for identifier in decoded.keys {
                    
                    // Count number of passes available to add to iPhone.
                    if !passIdentifiers.contains(identifier) {
                        availablePassesForIphone += 1
                    }
                    
                    // Count number of passes available to add to Apple Watch.
                    if !remotePassIdentifiers.contains(identifier) {
                        availableRemotePassesForAppleWatch += 1
                    }
                }
            } else {
                log.error("Error occurred while JSON decoding cachedCredentialsData")
            }
        } else {
            log.warning("Unable to find credentials of passes available to add to Apple Pay.")
        }
        
        // Set the status of the extension.
        status.passEntriesAvailable = availablePassesForIphone > 0
        status.remotePassEntriesAvailable = watchSession.isPaired && availableRemotePassesForAppleWatch > 0
        
        // Optionally, to avoid relying on a cached value,
        // set `requiresAuthentication` to `true` or `false` directly.
        status.requiresAuthentication = appGroupSharedDefaults.bool(forKey: "ShouldRequireAuthenticationForAppleWallet")
        
        // Invoke the completion handler.
        completion(status)
    }
    
    /**
     Return a list of pass entries that represent payment passes that are available to add to an iPhone.
     */
    override func passEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        
        // Pass this list to the completion handler.
        var passEntries: [PKIssuerProvisioningExtensionPassEntry] = []
        var paymentPassLibrary: [PKPass] = []
        var passLibraryIdentifiers: Set<String> = []
    
        // Get the identifiers of payment passes that already exist in Apple Pay.
        paymentPassLibrary = self.passLibrary.passes(of: .secureElement)
        
        for pass in paymentPassLibrary {
            if !pass.isRemotePass, let identifier = pass.secureElementPass?.primaryAccountIdentifier {
                passLibraryIdentifiers.insert(identifier)
            }
        }
        
        // Get cached credential data of all of the user's issued cards,
        // within the issuer app, from the user's defaults database.
        if let cachedCredentialsData = appGroupSharedDefaults.data(forKey: "PaymentPassCredentials") {
            
            // Decode the cached credential data of all of the user's
            // issued cards.
            // Note: `ProvisioningCredential` is not a member of PassKit.
            // Modify this logic based on how the issuer app
            // structures persisted data of an issued card.
            if let decoded = try? JSONDecoder().decode([String: ProvisioningCredential].self, from: cachedCredentialsData) {
                
                // Create a payment pass entry only for cards that are available
                // to add to Apple Pay, and add the entry to the `passEntries` list.
                for (identifier, paymentPassCredential) in decoded {
                    if !passLibraryIdentifiers.contains(identifier) {
                        let entry = getPaymentPassEntry(provisioningCredential: paymentPassCredential)
                        passEntries.append(entry)
                    }
                }
            } else {
                log.error("Error occurred while JSON decoding cachedCredentialsData")
            }
        } else {
            log.warning("Unable to find credentials of passes available to add to Apple Pay on iPhone.")
        }
        
        // Invoke the completion handler.
        completion(passEntries)
    }

    /**
     Return a list of pass entries that represent payment passes that are available to add to an Apple Watch.
     */
    override func remotePassEntries(completion: @escaping ([PKIssuerProvisioningExtensionPassEntry]) -> Void) {
        
        // Pass this list to the completion handler.
        var passEntries: [PKIssuerProvisioningExtensionPassEntry] = []
        var paymentPassLibrary: [PKPass] = []
        var passLibraryIdentifiers: Set<String> = []
    
        // Get the identifiers of payment passes that already exist in Apple Pay.
        paymentPassLibrary = self.passLibrary.passes(of: .secureElement)
        
        for pass in paymentPassLibrary {
            if pass.isRemotePass, pass.deviceName.localizedCaseInsensitiveContains("Apple Watch"),
               let identifier = pass.secureElementPass?.primaryAccountIdentifier {
                passLibraryIdentifiers.insert(identifier)
            }
        }
        
        // Get cached credentials data of all of the user's issued cards,
        // within the issuer app, from the user's defaults database.
        if let cachedCredentialsData = appGroupSharedDefaults.data(forKey: "PaymentPassCredentials") {
            
            // Decode the cached credential data of all of the user's
            // issued cards.
            // Note: `ProvisioningCredential` is not a member of PassKit.
            // Modify this logic based on how the issuer app
            // structures persisted data of an issued card.
            if let decoded = try? JSONDecoder().decode([String: ProvisioningCredential].self, from: cachedCredentialsData) {
                
                // Create a payment pass entry only for cards that are available
                // to add to Apple Pay, and add the entry to the `passEntries` list.
                for (identifier, paymentPassCredential) in decoded {
                    if !passLibraryIdentifiers.contains(identifier) {
                        let entry = getPaymentPassEntry(provisioningCredential: paymentPassCredential)
                        passEntries.append(entry)
                    }
                }
            } else {
                log.error("Error occurred while JSON decoding cachedCredentialsData")
            }
        } else {
            log.warning("Unable to find credentials of passes available to add to Apple Pay on Apple Watch.")
        }
        
        // Invoke the completion handler.
        completion(passEntries)
    }
    
    /**
     Generate a request to add a payment pass to Apple Pay based on the user's selection of the
     payment pass.
     */
    override func generateAddPaymentPassRequestForPassEntryWithIdentifier(_ identifier: String, configuration: PKAddPaymentPassRequestConfiguration,
                                                                          certificateChain certificates: [Data], nonce: Data, nonceSignature: Data,
                                                                          completionHandler completion: @escaping (PKAddPaymentPassRequest?) ->
                                                                          Void) {
        
        // Pass this request object to the completion handler.
        let request = PKAddPaymentPassRequest()
            
        // Generate the encrypted pass data.
        //
        // Note: `EncryptedPassDataResponse` and `PassResource` are not members of
        // PassKit. Modify this logic based on how the issuer app
        // retrieves the required encrypted pass data from the issuer server.
        //
        // Note: Use the `array.first(where:)` method to retrieve a
        // specific `PKLabeledValue` card detail from a `configuration.
        // configuration.cardDetails.first(where: { $0.label == "expiration" })!`
        let passData: EncryptedPassDataResponse = PassResource.requestPaymentPassData(configuration, certificateChain: certificates,
                                                                                      nonce: nonce, nonceSignature: nonceSignature)
        
        // Insert the encrypted pass data into the `PKAddPaymentPassRequest`.
        request.activationData = passData.activationData
        request.encryptedPassData = passData.encryptedPassData
        request.ephemeralPublicKey = passData.ephemeralPublicKey
        
        // Invoke the completion handler.
        completion(request)
    }
    
    // MARK: - Private Methods
    
    /**
     Return a payment pass entry.
     */
    private func getPaymentPassEntry(provisioningCredential: ProvisioningCredential) -> PKIssuerProvisioningExtensionPaymentPassEntry {
        
        // If using PNO Payment Data Configuration 1 (FPAN) or 3 (eFPAN), set
        // the identifier as the `primaryAccountNumber`. If using PNO Payment Data
        // Configuration 2 (FPANID), set the identifier as the
        // `primaryAccountIdentifier`.
        let identifier = provisioningCredential.primaryAccountIdentifier
        let label = provisioningCredential.label
        
        // Create a request configuration for adding a payment pass, to include in the payment pass entry.
        let requestConfig = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2)!
        requestConfig.primaryAccountIdentifier = identifier
        requestConfig.paymentNetwork = .masterCard
        requestConfig.cardholderName = provisioningCredential.cardholderName
        requestConfig.localizedDescription = provisioningCredential.localizedDescription
        requestConfig.primaryAccountSuffix = provisioningCredential.primaryAccountSuffix
        requestConfig.style = .payment
        
        // Append additional card details.
        requestConfig.cardDetails.append(PKLabeledValue(label: "expiration", value: provisioningCredential.expiration))
        
        // Instantiate and return a payment pass entry.
        if let uiImage = UIImage(named: provisioningCredential.assetName) {
            return PKIssuerProvisioningExtensionPaymentPassEntry(identifier: identifier,
                                                                 title: label,
                                                                 art: getEntryArt(image: uiImage),
                                                                 addRequestConfiguration: requestConfig)!
        } else {
            return PKIssuerProvisioningExtensionPaymentPassEntry(identifier: identifier,
                                                                 title: label,
                                                                 art: getEntryArt(image: #imageLiteral(resourceName: "generic")),
                                                                 addRequestConfiguration: requestConfig)!
        }
    }
    
    /**
     Convert a UIImage to a CGImage.
     */
    private func getEntryArt(image: UIImage) -> CGImage {
        let ciImage = CIImage(image: image)
        let ciContext = CIContext(options: nil)
        return ciContext.createCGImage(ciImage!, from: ciImage!.extent)!
    }
}
