/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view that provides the driver installation UI.
*/

import SwiftUI

struct CreatingMIDIDriverSampleAppView: View {
	@ObservedObject var viewModel = CreatingMIDIDriverSampleAppViewModel()
	var userClient = CreatingMIDIDriverSampleAppUserClient()
	@State var userClientText = ""

	var body: some View {
#if os(macOS)
		VStack(alignment: .center) {
			Text("Driver Manager")
				.padding()
				.font(.title)
			Text(self.viewModel.dextLoadingState)
				.multilineTextAlignment(.center)
			HStack {
				Button(
					action: {
						self.viewModel.activateMyDext()
					}, label: {
						Text("Install Dext")
					}
				)
			}
		}
		.frame(width: 500, height: 200, alignment: .center)
#endif
		VStack(alignment: .center) {
			Text("User Client Manager")
				.padding()
				.font(.title)
			Text(userClientText)
				.multilineTextAlignment(.center)
			HStack {
				Button(
					action: {
						userClientText = self.userClient.openConnection()
					}, label: {
						Text("Open User Client")
					}
				)
				Spacer()
				Button(
					action: {
						userClientText = self.userClient.addPort()
					}, label: {
						Text("Add Port")
					}
				)
				Spacer()
				Button(
					action: {
						userClientText = self.userClient.removePort()
					}, label: {
						Text("Remove Port")
					}
				)
				Spacer()
				Button(
					action: {
						userClientText = self.userClient.toggleOffline()
					}, label: {
						Text("Toggle Offline")
					}
				)
			}
		}
		.frame(width: 500, height: 200, alignment: .center)
	}
}

struct CreatingMIDIDriverSampleAppView_Previews: PreviewProvider {
	static var previews: some View {
		CreatingMIDIDriverSampleAppView()
	}
}
