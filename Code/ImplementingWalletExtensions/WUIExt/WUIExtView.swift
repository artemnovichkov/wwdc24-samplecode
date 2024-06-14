/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for the UI extension handler.
*/

import SwiftUI
import PassKit

struct WUIExtView: View {
    
    // Add the completion handler as an instance variable.
    var completionHandler: ((PKIssuerProvisioningExtensionAuthorizationResult) -> Void)?
    
    @State var username: String = ""
    @State var password: String = ""
    
    /**
     Handle a tap on the Log In button.
     */
    func handleLogin() {
        // Create username/password login logic.
        print("Log In button tapped")
        let randomNum = Int.random(in: 1..<10)
        let authorized = randomNum > 5 ? true : false
        
        // Call the completion handler.
        if authorized {
            completionHandler!(.authorized)
        } else {
            completionHandler!(.canceled)
        }
    }
    
    /**
     Handle a tap on the Face ID button.
     */
    func handleBiometricLogin() {
        // Create biometric login logic.
        print("Face ID button tapped")
        let randomNum = Int.random(in: 1..<10)
        let authorized = randomNum > 5 ? true : false
        
        // Call the completion handler.
        if authorized {
            completionHandler!(.authorized)
        } else {
            completionHandler!(.canceled)
        }
    }
   
    var body: some View {
        VStack {
            let smallConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .bold, scale: .small)
            if let banknoteLogo = UIImage(systemName: "banknote.fill", withConfiguration: smallConfig) {
                Image(uiImage: banknoteLogo.withRenderingMode(.alwaysTemplate))
                    .foregroundColor(.white)
                    .padding([.bottom], 10)
            }
            Text("Implementing Wallet Extensions Sample App")
                .font(.title)
                .bold()
                .padding([.bottom], 20)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            List {
                Section(header: Text("Login")) {
                    HStack {
                        Label("", systemImage: "person")
                        Spacer()
                        TextField("Username", text: $username)
                            .onAppear {
                                if username.isEmpty {
                                    username = "DemoUser"
                                }
                            }
                            .bold()
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Username Text Field")
                    .contentShape(Rectangle())
                    HStack {
                        Label("", systemImage: "lock")
                        Spacer()
                        SecureField("Password", text: $password)
                            .onAppear {
                                if password.isEmpty {
                                    password = "fakepassword"
                                }
                            }
                            .bold()
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Password Text Field")
                    .contentShape(Rectangle())
                }
                .padding(12)
                HStack(spacing: 18) {
                    Spacer()
                    Button(
                        action: handleBiometricLogin,
                        label: {
                            HStack {
                                Image(systemName: "faceid")
                                Text("Face ID")
                                    .bold()
                                    .font(.system(size: 16.0))
                            }
                            .padding(6)
                        }
                    )
                    .buttonStyle(.bordered)
                    .background(Color.blue)
                    .cornerRadius(26)
                    .foregroundColor(.white)
                    Button(
                        action: handleLogin,
                        label: {
                            Text("Log In")
                                .bold()
                                .font(.system(size: 16.0))
                                .padding(6)
                                .frame(width: 70)
                        }
                    )
                    .buttonStyle(.bordered)
                    .background(Color.orange)
                    .cornerRadius(26)
                    .foregroundColor(.white)
                }
                .listRowBackground(Color.clear)
            }
            VStack {
                Text("This start page is a demo login view.")
                    .foregroundColor(.white)
                    .padding()
                    .multilineTextAlignment(.center)
                    .fontWeight(.thin)
                HStack {
                    Link("Terms of Use",
                         destination: URL(string: "https://example.com")!)
                    Text("|")
                    Link("Privacy Policy",
                         destination: URL(string: "https://example.com")!)
                }
                .font(.system(size: 12))
                .foregroundColor(.white)
                .fontWeight(.light)
            }
        }
        .background(Color.blue)
    }
}
