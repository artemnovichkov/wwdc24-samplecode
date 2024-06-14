/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Delegate for handling the picker updates.
*/

import UIKit

extension ViewController: UIPickerViewDelegate {
    // MARK: - UIPickerViewDelegate
    
    /// When values are changed, update the predicted price.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updatePredictedPrice()
    }
    
    /// Accessor for picker values.
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let feature = Feature(rawValue: component) else {
            fatalError("Invalid component \(component) found to represent a \(Feature.self). This should not happen based on the configuration set in the storyboard.")
        }

        return pickerDataSource.title(for: row, feature: feature)
    }
}
