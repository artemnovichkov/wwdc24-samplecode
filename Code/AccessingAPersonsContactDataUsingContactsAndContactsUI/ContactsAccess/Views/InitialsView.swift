/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view the app uses to display the initials of a contact.
*/

import SwiftUI

struct InitialsView: View {
    let contact: Contact
    
    var body: some View {
        Text(contact.initials)
            .frame(width: 40, height: 40)
            .background(Color.gray)
            .clipShape(Circle())
    }
}

#Preview {
    InitialsView(contact: Contact.sample)
}
