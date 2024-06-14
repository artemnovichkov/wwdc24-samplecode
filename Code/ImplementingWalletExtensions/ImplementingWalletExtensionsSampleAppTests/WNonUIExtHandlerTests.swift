/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The tests for the non-UI extension.
*/
import XCTest
import PassKit

final class WNonUIExtHandlerTests: XCTestCase {

    func testStatus() {
        
        // Create mock objects.
        let mockUserDefaults = MockUserDefaults()
        let mockPassLibrary = MockPKPassLibrary()
        let mockWatchSession = MockWatchConnectivitySession()
        
        // Initialize `WNonUIExtHandler` with mock objects.
        let nonUIExt = WNonUIExtHandler(passLibrary: mockPassLibrary, sharedDefaults: mockUserDefaults, watchSession: mockWatchSession)
        
        // Create pass 1 (available for Apple Watch).
        let pass1 = MockPKPass(primaryAccountIdentifier: "123", isRemote: false)
        mockUserDefaults.addPassCredentialJson("123", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "1234", expiration: "10/28")
        
        // Create pass 2 (available for Apple Watch).
        let pass2 = MockPKPass(primaryAccountIdentifier: "456", isRemote: false)
        mockUserDefaults.addPassCredentialJson("456", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "4567", expiration: "01/28")
        
        // Create pass 3 (available for iPhone & Apple Watch).
        mockUserDefaults.addPassCredentialJson("789", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "7891", expiration: "03/28")
        
        // Add passes to the mock pass library.
        mockPassLibrary.mockPasses = [pass1, pass2]
        
        // Create a status object with the expected values for its
        // instance properties.
        let expectedStatus = PKIssuerProvisioningExtensionStatus()
        expectedStatus.passEntriesAvailable = true
        expectedStatus.remotePassEntriesAvailable = true
        expectedStatus.requiresAuthentication = true
        
        // Create a status object to store the actual result of calling the
        // non-UI extension's status method.
        var actualStatus: PKIssuerProvisioningExtensionStatus?
        
        // Create a stub completion handler.
        func statusCompletion(_ status: PKIssuerProvisioningExtensionStatus) {
            actualStatus = status
        }
        
        // Call the status method with the completion handler.
        nonUIExt.status(completion: statusCompletion)

        // Compare the expected status with the actual status.
        XCTAssertEqual(expectedStatus, actualStatus)
    }
    
    func testStatusForAvailableIPhonePassesOnly() {
        
        // Create mock objects.
        let mockUserDefaults = MockUserDefaults()
        let mockPassLibrary = MockPKPassLibrary()
        let mockWatchSession = MockWatchConnectivitySession()
        
        // Initialize `WNonUIExtHandler` with mock objects.
        let nonUIExt = WNonUIExtHandler(passLibrary: mockPassLibrary, sharedDefaults: mockUserDefaults, watchSession: mockWatchSession)
        
        // Create pass 1 (available for iPhone).
        let pass1 = MockPKPass(primaryAccountIdentifier: "123", isRemote: true)
        mockUserDefaults.addPassCredentialJson("123", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "1234", expiration: "10/28")
        
        // Create pass 2 (available for iPhone).
        let pass2 = MockPKPass(primaryAccountIdentifier: "456", isRemote: true)
        mockUserDefaults.addPassCredentialJson("456", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "4567", expiration: "01/28")
        
        // Add passes to the mock pass library.
        mockPassLibrary.mockPasses = [pass1, pass2]
        
        // Create a status object with the expected values for its
        // instance properties.
        let expectedStatus = PKIssuerProvisioningExtensionStatus()
        expectedStatus.passEntriesAvailable = true
        expectedStatus.remotePassEntriesAvailable = false
        expectedStatus.requiresAuthentication = true
        
        // Create a status object to store the actual result of calling the
        // non-UI extension's status method.
        var actualStatus: PKIssuerProvisioningExtensionStatus?
        
        // Create a stub completion handler.
        func statusCompletion(_ status: PKIssuerProvisioningExtensionStatus) {
            actualStatus = status
        }
        
        // Call the status method with the completion handler.
        nonUIExt.status(completion: statusCompletion)
        
        // Compare the expected status with the actual status.
        XCTAssertEqual(expectedStatus, actualStatus)
    }
    
    func testStatusForAvailableRemotePassesOnly() {
        
        // Create mock objects.
        let mockUserDefaults = MockUserDefaults()
        let mockPassLibrary = MockPKPassLibrary()
        let mockWatchSession = MockWatchConnectivitySession()
        
        // Initialize `WNonUIExtHandler` with mock objects.
        let nonUIExt = WNonUIExtHandler(passLibrary: mockPassLibrary, sharedDefaults: mockUserDefaults, watchSession: mockWatchSession)
        
        // Create pass 1 (available for Apple Watch).
        let pass1 = MockPKPass(primaryAccountIdentifier: "123", isRemote: false)
        mockUserDefaults.addPassCredentialJson("123", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "1234", expiration: "10/28")
        
        // Create pass 2 (available for Apple Watch).
        let pass2 = MockPKPass(primaryAccountIdentifier: "456", isRemote: false)
        mockUserDefaults.addPassCredentialJson("456", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "4567", expiration: "01/28")
         
        // Add passes to the mock pass library.
        mockPassLibrary.mockPasses = [pass1, pass2]
        
        // Create a status object with the expected values for its
        // instance properties.
        let expectedStatus = PKIssuerProvisioningExtensionStatus()
        expectedStatus.passEntriesAvailable = false
        expectedStatus.remotePassEntriesAvailable = true
        expectedStatus.requiresAuthentication = true
        
        // Create a status object to store the actual result of calling the
        // non-UI extension's status method.
        var actualStatus: PKIssuerProvisioningExtensionStatus?
        
        // Create a stub completion handler.
        func statusCompletion(_ status: PKIssuerProvisioningExtensionStatus) {
            actualStatus = status
        }
        
        // Call the status method with the completion handler.
        nonUIExt.status(completion: statusCompletion)
        
        // Compare the expected status with the actual status.
        XCTAssertEqual(expectedStatus, actualStatus)
    }
    
    func testPassEntriesForIphone() {
        
        // Create mock objects.
        let mockUserDefaults = MockUserDefaults()
        let mockPassLibrary = MockPKPassLibrary()
        let mockWatchSession = MockWatchConnectivitySession()
        
        // Initialize `WNonUIExtHandler` with mock objects.
        let nonUIExt = WNonUIExtHandler(passLibrary: mockPassLibrary, sharedDefaults: mockUserDefaults, watchSession: mockWatchSession)
        
        // Create pass 1.
        let pass1A = MockPKPass(primaryAccountIdentifier: "123", isRemote: false)
        let pass1B = MockPKPass(primaryAccountIdentifier: "123", isRemote: true)
        mockUserDefaults.addPassCredentialJson("123", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "1234", expiration: "10/28")
        
        // Create pass 2 (available for Apple Watch).
        let pass2 = MockPKPass(primaryAccountIdentifier: "456", isRemote: false)
        mockUserDefaults.addPassCredentialJson("456", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "4567", expiration: "01/28")
        
        // Create pass 3 (available for iPhone and Apple Watch).
        mockUserDefaults.addPassCredentialJson("789", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "7891", expiration: "03/28")
        
        // Add passes to mock pass library.
        mockPassLibrary.mockPasses = [pass1A, pass1B, pass2]
        
        // Create an array to store the actual list of pass entries
        // the system creates when calling the non-UI extension's pass entries method.
        var entries: [PKIssuerProvisioningExtensionPassEntry] = []
        
        // Create a stub completion handler.
        func passEntriesCompletion(_ passEntries: [PKIssuerProvisioningExtensionPassEntry]) {
            entries = passEntries
        }
        
        // Call the pass entries method with the completion handler.
        nonUIExt.passEntries(completion: passEntriesCompletion)
        
        // Get the first pass entry from the list. The test run should result
        // in the list containing only one pass entry.
        var entry: PKIssuerProvisioningExtensionPaymentPassEntry?
        if !entries.isEmpty {
            entry = entries[0] as? PKIssuerProvisioningExtensionPaymentPassEntry
        }
        
        // Create the expected expiration.
        let expectedExpirationLabel = PKLabeledValue(label: "expiration", value: "03/28")
        
        // Extract the actual expiration.
        let actualExpirationLabel = entry?.addRequestConfiguration.cardDetails.first(where: { $0.label == "expiration" })
        
        // Compare the expected data against the actual data of the pass entry.
        XCTAssertNotNil(entry)
        XCTAssertEqual(1, entries.count)
        XCTAssertEqual("789", entry?.identifier)
        XCTAssertEqual("789", entry?.addRequestConfiguration.primaryAccountIdentifier)
        XCTAssertEqual("7891", entry?.addRequestConfiguration.primaryAccountSuffix)
        XCTAssertEqual("Johnny Appleseed", entry?.addRequestConfiguration.cardholderName)
        XCTAssertEqual(expectedExpirationLabel, actualExpirationLabel)
    }
    
    func testPassEntriesForIphoneWithNoAvailablePasses() {
        
        // Create mock objects.
        let mockUserDefaults = MockUserDefaults()
        let mockPassLibrary = MockPKPassLibrary()
        let mockWatchSession = MockWatchConnectivitySession()
        
        // Initialize `WNonUIExtHandler` with mock objects.
        let nonUIExt = WNonUIExtHandler(passLibrary: mockPassLibrary, sharedDefaults: mockUserDefaults, watchSession: mockWatchSession)
        
        // Create pass 1 (available for Apple Watch).
        let pass1 = MockPKPass(primaryAccountIdentifier: "123", isRemote: false)
        mockUserDefaults.addPassCredentialJson("123", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "1234", expiration: "10/28")
        
        // Create pass 2 (available for Apple Watch).
        let pass2 = MockPKPass(primaryAccountIdentifier: "456", isRemote: false)
        mockUserDefaults.addPassCredentialJson("456", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "4567", expiration: "01/28")
        
        // Add passes to mock pass library.
        mockPassLibrary.mockPasses = [pass1, pass2]
        
        // Create an array to store the actual list of pass entries that the
        // system creates when calling the non-UI extension's pass entries method.
        var entries: [PKIssuerProvisioningExtensionPassEntry] = []
        
        // Create a stub completion handler.
        func passEntriesCompletion(_ passEntries: [PKIssuerProvisioningExtensionPassEntry]) {
            entries = passEntries
        }
        
        // Call the pass entries method with the completion handler.
        nonUIExt.passEntries(completion: passEntriesCompletion)
        
        // Compare the expected data against the actual data of the pass entry.
        XCTAssertEqual(0, entries.count)
    }
    
    func testRemotePassEntriesForAppleWatch() {
        
        // Create mock objects.
        let mockUserDefaults = MockUserDefaults()
        let mockPassLibrary = MockPKPassLibrary()
        let mockWatchSession = MockWatchConnectivitySession()
        
        // Initialize `WNonUIExtHandler` with mock objects.
        let nonUIExt = WNonUIExtHandler(passLibrary: mockPassLibrary, sharedDefaults: mockUserDefaults, watchSession: mockWatchSession)
        
        // Create pass 1.
        let pass1A = MockPKPass(primaryAccountIdentifier: "123", isRemote: false)
        let pass1B = MockPKPass(primaryAccountIdentifier: "123", isRemote: true)
        mockUserDefaults.addPassCredentialJson("123", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "1234", expiration: "10/28")
        
        // Create pass 2 (available for Apple Watch).
        let pass2 = MockPKPass(primaryAccountIdentifier: "456", isRemote: false)
        mockUserDefaults.addPassCredentialJson("456", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "4567", expiration: "01/28")
        
        // Add passes to mock pass library.
        mockPassLibrary.mockPasses = [pass1A, pass1B, pass2]
        
        // Create an array to store the actual list of pass entries that the
        // system creates when calling the Non-UI extension's pass entries method.
        var entries: [PKIssuerProvisioningExtensionPassEntry] = []
        
        // Create a stub completion handler.
        func passEntriesCompletion(_ passEntries: [PKIssuerProvisioningExtensionPassEntry]) {
            entries = passEntries
        }
        
        // Call the remote pass entries method with the completion handler.
        nonUIExt.remotePassEntries(completion: passEntriesCompletion)
        
        // Get the first pass entry from the list. The test run should result
        // in the list containing only one pass entry.
        var entry: PKIssuerProvisioningExtensionPaymentPassEntry?
        if !entries.isEmpty {
            entry = entries[0] as? PKIssuerProvisioningExtensionPaymentPassEntry
        }
        
        // Create the expected expiration.
        let expectedExpirationLabel = PKLabeledValue(label: "expiration", value: "01/28")
        
        // Extract the actual expiration.
        let actualExpirationLabel = entry?.addRequestConfiguration.cardDetails.first(where: { $0.label == "expiration" })
        
        // Compare the expected data against the actual data of the pass entry.
        XCTAssertNotNil(entry)
        XCTAssertEqual(1, entries.count)
        XCTAssertEqual("456", entry?.identifier)
        XCTAssertEqual("456", entry?.addRequestConfiguration.primaryAccountIdentifier)
        XCTAssertEqual("4567", entry?.addRequestConfiguration.primaryAccountSuffix)
        XCTAssertEqual("Johnny Appleseed", entry?.addRequestConfiguration.cardholderName)
        XCTAssertEqual(expectedExpirationLabel, actualExpirationLabel)
    }
    
    func testRemotePassEntriesForAppleWatchWithNoAvailableRemotePasses() {
        
        // Create mock objects.
        let mockUserDefaults = MockUserDefaults()
        let mockPassLibrary = MockPKPassLibrary()
        let mockWatchSession = MockWatchConnectivitySession()
        
        // Initialize `WNonUIExtHandler` with mock objects.
        let nonUIExt = WNonUIExtHandler(passLibrary: mockPassLibrary, sharedDefaults: mockUserDefaults, watchSession: mockWatchSession)
        
        // Create pass 1.
        let pass1A = MockPKPass(primaryAccountIdentifier: "123", isRemote: false)
        let pass1B = MockPKPass(primaryAccountIdentifier: "123", isRemote: true)
        mockUserDefaults.addPassCredentialJson("123", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "1234", expiration: "10/28")
        
        // Create pass 2.
        let pass2A = MockPKPass(primaryAccountIdentifier: "456", isRemote: false)
        let pass2B = MockPKPass(primaryAccountIdentifier: "456", isRemote: true)
        mockUserDefaults.addPassCredentialJson("456", cardholderName: "Johnny Appleseed",
                                               primaryAccountSuffix: "4567", expiration: "01/28")
        
        // Add passes to mock pass library.
        mockPassLibrary.mockPasses = [pass1A, pass1B, pass2A, pass2B]
        
        // Create the pass library.
        var entries: [PKIssuerProvisioningExtensionPassEntry] = []
        
        // Create a stub completion handler.
        func passEntriesCompletion(_ passEntries: [PKIssuerProvisioningExtensionPassEntry]) {
            entries = passEntries
        }
        
        // Call the remote pass entries method with the completion handler.
        nonUIExt.remotePassEntries(completion: passEntriesCompletion)
        
        // Compare the expected data against the actual data of the pass entry.
        XCTAssertEqual(0, entries.count)
    }
    
    func testGenerateAddPaymentPassRequest() {
        
        // Create mock objects.
        let mockUserDefaults = MockUserDefaults()
        let mockPassLibrary = MockPKPassLibrary()
        let mockWatchSession = MockWatchConnectivitySession()
        
        // Initialize `WNonUIExtHandler` with mock objects.
        let nonUIExt = WNonUIExtHandler(passLibrary: mockPassLibrary, sharedDefaults: mockUserDefaults, watchSession: mockWatchSession)
        
        // Create the objects to pass as parameters of the generate
        // method to add a payment pass request.
        let identifier = "123"
        let config = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2)!
        let certificateChain: [Data] = []
        let nonce = Data()
        let nonceSignature = Data()
        
        // Create a request object to store the actual result of calling the
        // non-UI extension's generate method to add a payment pass.
        var actualRequest: PKAddPaymentPassRequest?
        
        // Create a stub completion handler.
        func generateRequestCompletion(_ request: PKAddPaymentPassRequest?) {
            actualRequest = request
        }
        
        // Call the generate method with the required parameters,
        // including the completion handler.
        nonUIExt.generateAddPaymentPassRequestForPassEntryWithIdentifier(identifier,
                                                                         configuration: config,
                                                                         certificateChain: certificateChain,
                                                                         nonce: nonce,
                                                                         nonceSignature: nonceSignature,
                                                                         completionHandler: generateRequestCompletion)
        
        // Assert that the actual request object's data is not nil.
        XCTAssertNotNil(actualRequest)
        XCTAssertNotNil(actualRequest?.activationData)
        XCTAssertNotNil(actualRequest?.encryptedPassData)
        XCTAssertNotNil(actualRequest?.ephemeralPublicKey)
    }
}
