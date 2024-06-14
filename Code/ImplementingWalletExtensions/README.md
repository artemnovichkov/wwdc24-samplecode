# Implementing Wallet Extensions

Support adding an issued card to Apple Pay from directly within Apple Wallet 
using Wallet Extensions.

## Overview

Apple Pay in-app provisioning relies on the individual to add a payment pass from within the issuer app, 
and requires this person to already be in the issuer app with the intention of adding the pass. To make it 
easier for people to add a payment pass to Apple Pay directly within Apple Wallet, Apple Pay offers extensions 
for in-app provisioning, called Wallet Extensions. Wallet Extensions improve discoverability of the option to add
an issued card to Apple Wallet, as people can tap a button within Apple Wallet to begin a provisioning 
experience that doesn't require them to enter details manually.

Use this sample as a guide for developing the Wallet Extensions feature. The feature relies on two extensions, 
a UI extension and a non-UI extension. The issuer app needs a non-UI extension to report on the status of the 
extension and passes the app has available to add, and to perform the card data lookup—just like when adding payment 
passes to Apple Wallet from within the issuer app via in-app provisioning.

As for the UI extension, the issuer app needs a UI extension to perform user authentication if the non-UI 
extension reports that authentication is required. The UI extension isn’t a redirect to the issuer app, but a 
separate screen that uses the same issuer app login credentials.

The project contains four targets:
* `ImplementingWalletExtensionsSampleApp` - A containing app sample
* `WUIExt` - A UI extension sample
* `WNonUIExt` - A non-UI extension sample
* `ImplementingWalletExtensionsSampleAppTests` - A unit-testing bundle with sample tests


For more information on Wallet Extensions, see
the [Apple Pay Demo - Wallet Extensions documentation](https://applepaydemo.apple.com/wallet-extensions).

## Configure the sample code project 

Because Wallet Extensions require an entitlement from Apple, you can't run the app extensions in 
this sample. You can only run the sample unit tests and the sample containing app, which has a login view that is 
repurposed for the UI extension during the Wallet Extensions process. To run this sample you'll need the following:

* Xcode 15 or later
* iOS 14 or later (for Wallet Extensions)
