/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view where the user can select a drink from the list of available drinks.
*/

import CoffeeKit
import SwiftUI

// Display a list of drinks.
// The user can select drinks from the list.
struct DrinkListView: View {

    @EnvironmentObject var coffeeData: CoffeeData
    @Environment(\.presentationMode) var presentationMode

    // Lay out the view's body.
    var body: some View {
        List {
            // Add a tappable row for each drink.
            ForEach(DrinkType.allCases) { drinkType in
                Button(action: { self.addDrink(type: drinkType) }) {
                    Text(drinkType.name)
                }
            }
        }
    }

    // Update the model when the user taps a drink.
    func addDrink(type: DrinkType) {
        Task {
            // Add a drink to the model.
            await coffeeData.addDrink(type: type, onDate: Date())
        }

        // Dismiss the view.
        presentationMode.wrappedValue.dismiss()
    }
}

// Configure a preview of the drink list view.
struct DrinkListView_Previews: PreviewProvider {
    static var previews: some View {
        DrinkListView()
    }
}
