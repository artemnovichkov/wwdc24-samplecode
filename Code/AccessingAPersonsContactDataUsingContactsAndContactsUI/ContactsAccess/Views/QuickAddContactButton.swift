/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button that presents the Contact access button.
*/

import SwiftUI
import ContactsUI

struct QuickAddContactButton: View {
    @Environment(ContactStoreManager.self) private var storeManager
    @Environment(IgnoreItemModel.self) private var model
    
    @Binding var lastAddedIdentifiers: Set<String>
    @Binding var searchText: String
    @Binding var caption: CaptionOrder
    
    private var emails: [String] {
        model.ignoredEmails.map({ $0.item })
    }
    
    private var phoneNumbers: [String] {
        model.ignoredPhoneNumbers.map({ $0.item })
    }
    
    var body: some View {
        /*
            You can use the contact access button to allow people to add additional
            contacts to the list of contacts authorized for your app from within
            your app. The button renders when the authorization status of your
            app isn't determined or limited. When someone searches for a contact
            that doesn't appear in the list of contacts the person approves for
            your app, the button performs a search query with parameters you provide
            and presents this contact in its search result. If the person taps the
            button, the system immediately grants your app access to the contact
            without prompting the person for permission. Your app receives a
            callback that includes the identifier of the newly added contact.
         
            The sample app displays the contact access button when it has limited
            access authorization. The app displays a search field in its search
            list view. When the person enters text in the search field, the app
            calls the button with the entered text. If the person configured email
            addresses and phone numbers to ignore in the app's ignore list view,
            the app passes this data to the button. The app fetches the contacts
            whose identifiers the button returns, appends them to the contacts list
            shown in the seach list view, then highlights them. The app allows
            people to specify whether to display the contact's email address, phone number,
            or default value below the contact in the search results of the contact
            access button.
        */
        ContactAccessButton(queryString: searchText, ignoredEmails: Set(emails), ignoredPhoneNumbers: Set(phoneNumbers)) { identifiers in
            if !identifiers.isEmpty {
                searchText = ""
            }
            
            lastAddedIdentifiers = Set(identifiers)
            Task {
                await storeManager.fetchContacts(withIdentifiers: identifiers)
            }
            
        }
        .buttonBorderShape(.circle)
        // Set the contact access button caption to the caption option that the person selects in the app.
        .contactAccessButtonCaption(caption.bottomCaption)
        .contactAccessButtonStyle(ContactAccessButton.Style(imageTrailingEdgePadding: 2,
                                                              imageWidth: 40,
                                                              imageColor: Color.red))
    }
}

#Preview {
    QuickAddContactButton(lastAddedIdentifiers: .constant([]), searchText: .constant("john"), caption: .constant(.email) )
        .environment(ContactStoreManager())
        .environment(IgnoreItemModel())
}
