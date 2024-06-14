/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions.
*/

import Foundation

func dateFromYear(_ year: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year))!
}
