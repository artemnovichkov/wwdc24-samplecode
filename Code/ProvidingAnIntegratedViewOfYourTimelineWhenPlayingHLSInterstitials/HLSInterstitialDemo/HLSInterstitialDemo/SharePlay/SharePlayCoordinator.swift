/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SharePlay coordinator for the shared activity.
*/
import Combine
import Foundation
import GroupActivities
import os

actor SharePlayCoordinator {
    private var currentSession: GroupSession<VideoWatchingActivity>?
    private var subscriptions = [AnyCancellable]()
    static let shared = SharePlayCoordinator()

    // MARK: - Life cycle

    private init() {}

    // MARK: - Public

    enum SharedContent: Sendable {
        case none
        case video(metadata: VideoMetadata)
    }

    let sharedContent = AsyncPassthroughValue<SharedContent>()
    var isRunningActivity = false

    func unsafeCurrentSession() -> UnsafeSendable<GroupSession<VideoWatchingActivity>>? {
        guard let currentSession else { return nil }
        return UnsafeSendable(wrappedValue: currentSession)
    }

    func resume() async {
        Logger.general.log("[SharePlayCoordinator] Resuming SharePlay session browsing")

        // Await new sessions to watch movies together.
        for await session in VideoWatchingActivity.sessions() {
            Logger.general.log("[SharePlayCoordinator] Received MovieWatching session")
            await tearDown()

            // Set the app's active group session.
            currentSession = session

            // Observe changes to the session state.
            session.$state.sink { [weak self] state in
                switch state {
                case .waiting:
                    Logger.general.log("[SharePlayCoordinator] Waiting to joining group session")

                case .joined:
                    Logger.general.log("[SharePlayCoordinator] Group session joined")

                case .invalidated(let reason):
                    Task { [weak self] in
                        Logger.general.error("[SharePlayCoordinator] Group session was invalidated. Error: \(String(describing: reason))")
                        await self?.tearDown()
                    }

                @unknown default:
                    break
                }
            }
            .store(in: &subscriptions)

            // Observe when the local user or a remote participant starts an activity.
            session.$activity.sink { [weak self] activity in
                Task { [weak self] in
                    Logger.general.log("[SharePlayCoordinator] Received MovieWatching activity: \(String(describing: activity))")
                    await self?.receive(activity)
                }
            }
            .store(in: &subscriptions)

            // Join the session to participate in playback coordination.
            session.join()
        }
    }

    func tearDown() async {
        guard let session = currentSession else { return }
        Logger.general.log("[SharePlayCoordinator] Tearing down existing group session")
        
        // Clear current session and remove previous subscriptions.
        session.end()
        currentSession = nil
        subscriptions.removeAll()
        await sharedContent.send(.none)
        isRunningActivity = false
    }

    // MARK: - Private

    private func receive(_ activity: VideoWatchingActivity) async {
        // Send activity details to remote participants.
        guard currentSession != nil else { return }
        isRunningActivity = true
        await sharedContent.send(.video(metadata: activity.videoMetadata))
    }
}
