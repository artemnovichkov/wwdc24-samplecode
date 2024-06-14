/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows information about a contact.
*/

import SwiftUI
import SwiftData
import AVFoundation

/// The entry point for creating and customizing a custom sound for a contact
/// alert message.
struct ContactAlertView: View {
    let contact: Contact
    private var manager = SoundDropManager()
    
    init(contact: Contact) {
        self.contact = contact
    }

    var body: some View {
        VStack {
            ContactAlertHeaderView(contact: contact)
            ContactAlertPlayer(contact: contact, manager: manager)

            Divider()

            Grid {
                GridRow {
                    SoundRow(sound: .fans)
                    SoundRow(sound: .synth)
                    SoundRow(sound: .bells)
                }
                GridRow {
                    SoundRow(sound: .rattle)
                    SoundRow(sound: .fork)
                    SoundRow(sound: .rain)
                }
            }
            .padding(.bottom)
        }
        .padding()
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            manager.sounds = contact.alert
        }
    }
}

private struct ContactAlertHeaderView: View {
    let contact: Contact

    var body: some View {
        VStack {
            Text(contact.name)
                .font(.title)
                .fontWeight(.medium)
            Text("Comment Alert")
                .accessibilityAddTraits(.isHeader)
                .font(.caption)
                .fontWeight(.bold)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom)
        .accessibilityElement(children: .combine)
        // Indicate the title is a header to accessibility clients.
        .accessibilityAddTraits(.isHeader)
    }
}

private struct ContactAlertPlayer: View {
    let contact: Contact
    let manager: SoundDropManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            Button(action: manager.togglePlayAction) {
                ZStack(alignment: .center) {
                    Circle()
                        .foregroundStyle(.orange)
                        .shadow(radius: 5)
                    Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.borderless)
            // Provide a custom shape that matches the visuals of the button for
            // the accessibility cursor of clients like VoiceOver to follow.
            .contentShape(.accessibility, Circle())
            // Indicate clients should not re-read the title of the button because
            // a sound will be played.
            .accessibilityAddTraits(.startsMediaSession)

            HStack {
                ForEach(manager.sounds) {
                    SoundItem(sound: $0.sound)
                }
            }
            .frame(width: 215, height: 75)
            .padding(.horizontal)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(.quaternary.shadow(
                        .inner(color: .black.opacity(0.4), radius: 4)))
            }
            .accessibilityElement()
            // Provide a custom label that includes the concatenated alert sounds.
            .accessibilityLabel { _ in
                Text("Alert")
                if manager.sounds.isEmpty {
                    Text("No Sounds")
                } else {
                    ForEach(manager.sounds) {
                        Text($0.sound.name)
                    }
                }
            }
            // Expose three drop points at each end of the rectangle to support
            // dropping three different sounds at different locations in the player.
            .accessibilityDropPoint(UnitPoint(x: 0.1, y: 0.5), description: "Set Sound 1")
            .accessibilityDropPoint(.center, description: "Set Sound 2")
            .accessibilityDropPoint(UnitPoint(x: 0.9, y: 0.5), description: "Set Sound 3")
            .onDrop(of: [.text], delegate: manager)
            .onChange(of: manager.sounds) { _, newValue in
                guard contact.alert != newValue else {
                    return
                }
                contact.alert = newValue
                try? modelContext.save()
            }
        }
        .frame(height: 75)
        .padding(.bottom)
    }
}

private struct SoundRow: View {
    var sound: Contact.Sound

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .foregroundStyle(.blue.mix(with: .gray, by: 0.3))
                .shadow(radius: 5)
                .frame(width: 90, height: 90)
            VStack {
                Image(systemName: "speaker.wave.3.fill")
                    .bold()
                    .padding(.bottom, 1)
                Text(sound.name)
            }
            .foregroundStyle(.white)
            .frame(width: 70, height: 70)
        }
        .accessibilityElement(children: .combine)
        .draggable(sound)
    }
}

private struct SoundItem: View {
    var sound: Contact.Sound

    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(.green)
                .shadow(color: .black.opacity(0.2), radius: 5)
                .frame(width: 65, height: 65)
            VStack {
                Image(systemName: "speaker.wave.3.fill")
                    .bold()
            }
            .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The delegate managing both the playing of a custom set of sounds as well as
/// adding sounds to be played as a `DropDelegate`.
@Observable
final private class SoundDropManager: NSObject, DropDelegate, AVAudioPlayerDelegate {
    private static let maxSoundCount = 3

    var sounds: [Contact.SoundItem] = []
    var isPlaying = false
    private var audioPlayer: AVAudioPlayer?

    func togglePlayAction() {
        if isPlaying {
            audioPlayer?.stop()
            audioPlayer = nil
            isPlaying.toggle()
        } else {
            if let sound = sounds.randomElement()?.sound,
               let path = pathForSound(sound),
               let player = try? AVAudioPlayer(contentsOf: path) {
                player.delegate = self
                player.prepareToPlay()
                player.play()
                audioPlayer = player
                isPlaying.toggle()
            }
        }
        
    }

    private func pathForSound(_ sound: Contact.Sound) -> URL? {
        let file = sound.file
        return Bundle.main.path(forResource: file.name, ofType: file.type).flatMap {
            URL(fileURLWithPath: $0)
        }
    }
    
    // MARK: Audio Delegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        audioPlayer = nil
    }
    
    // MARK: Drop Delegate

    func performDrop(info: DropInfo) -> Bool {
        guard sounds.count < Self.maxSoundCount else { return false }
        let providers = info.itemProviders(for: [.text])
        guard !providers.isEmpty else { return false }
        let point = info.location
        _ = providers[0].loadTransferable(type: Contact.Sound.self) { result in
            guard case .success(let sound) = result else {
                return
            }
            Task { @MainActor in
                self.sounds.append(.init(point: point, sound: sound))
                // Sort the drops by which was dropped the closest to the leading
                // position of the player.
                self.sounds.sort {
                    $0.point.x < $1.point.x
                }
            }
        }
        return true
    }
}
