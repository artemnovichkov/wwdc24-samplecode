# Enhancing the accessibility of your SwiftUI app

Support advancements in SwiftUI accessibility to make your app accessible to everyone.

## Overview

- Note: This sample code project is associated with WWDC24 session 10073: [Catch up on accessibility in SwiftUI](https://developer.apple.com/wwdc24/10073/).

## Configure the sample code project

Open the sample code project in Xcode. Before building it, do the following:

1. Set the developer team for all targets to your team so Xcode automatically manages the provisioning profile. For more information, see [Assign a project to a team](https://help.apple.com/xcode/mac/current/#/dev23aab79b4).
2. Replace the App Group container identifier — `group.SwiftUIAccessibilityWWDCSample` — with one specific to your team for the entire project. The identifier points to an App Group container that the app and widget use to share data. You can search for `group.SwiftUIAccessibilityWWDCSample` using the Find navigator in Xcode, and then change all of the occurrences (except those in this `README` file). For more information, see [Configuring App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups).
