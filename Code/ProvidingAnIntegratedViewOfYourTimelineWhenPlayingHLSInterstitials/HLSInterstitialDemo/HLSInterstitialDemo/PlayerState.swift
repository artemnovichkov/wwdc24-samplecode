/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The player to track player states.
*/
import AVKit
import AVFoundation
import Combine
import Observation
import os

@Observable
final class PlayerState {
    // Set up the player state variables.
    private let menuItem: MenuItem
    private let videoMetadata: VideoMetadata
    private let queue = DispatchQueue(label: "com.example.apple-samplecode.HLSInterstitialDemo.PlayerState.queue")
    private var subscriptions = [AnyCancellable]()
	public var primaryAssetIdentifier = UUID()
    
    public var isPlayingLiveStream = false
    public var playerRate: Float = 0.0
    
    // Initialize the integrated timeline values.
    public var integratedTimelineCurrentTime: Double = 0.0
    public var integratedTimelineStartTime: Double = 0.0
    public var integratedTimelineDuration: Double = 0.0
    
    public var integratedTimelinePointSegments: [AVPlayerItemSegment] = []
    public var integratedTimelineFillSegments: [AVPlayerItemSegment] = []

    // Variables for duration and time observations.
    private var durationObservation: NSKeyValueObservation?
    private var integratedTimelineCurrentTimeTimer: AnyCancellable?

    @ObservationIgnored
    private lazy var playbackCoordinatorDelegate = PlayerCoordinatorDelegate(menuItem: menuItem)

    @ObservationIgnored
    private lazy var interstitialEventController = AVPlayerInterstitialEventController(primaryPlayer: player)

    // MARK: - Life cycle

    init(menuItem: MenuItem, videoMetadata: VideoMetadata) {
        Logger.general.log("[PlayerState] initializing with item \(String(describing: menuItem))")

        self.menuItem = menuItem
        self.videoMetadata = videoMetadata

        // Schedule and observe interstitial events.
        beginObservingEvents()
        scheduleInterstitialEvents()
    }
    
    // MARK: - Private - Computed Values

    private var shouldInsertPeriodicInterstitials: Bool {
        menuItem.playbackBehaviors?.contains(.insertPeriodicInterstitial) ?? false
    }
    
    // MARK: - Private - Components

    @ObservationIgnored
    private lazy var playerItem: AVPlayerItem = {
        // Create playerItem from item URL.
        let asset = AVURLAsset(url: menuItem.url)
        primaryAssetIdentifier = asset.httpSessionIdentifier
        
        let playerItem = AVPlayerItem(asset: asset)

        return playerItem
    }()

    @ObservationIgnored
    lazy var player: AVPlayer = {
        // Create player from playerItem.
        let player = AVPlayer(playerItem: self.playerItem)
        player.playbackCoordinator.delegate = playbackCoordinatorDelegate

        Task { @MainActor in
            Logger.general.log("[PlayerState] Coordinate with group session")
            
            // Coordinate with group if there is an existing SharePlay activity.
            if SharePlayCoordinator.shared.isRunningActivity {
                await coordinateWithGroupSession()
                return
            }
        }

        return player
    }()

    @ObservationIgnored
    lazy var integratedTimeline: AVPlayerItemIntegratedTimeline = {
        // Create the integrated timeline.
        let integratedTimeline = player.currentItem!.integratedTimeline
        
        return integratedTimeline
    }()

    // MARK: - Private - Interstitial Event Scheduling

    private func makeInterstitialEventsFromMenuItem() -> [AVPlayerInterstitialEvent] {
        // Create interstitial events from the JSON menu.
        
        return (menuItem.interstitialEvents ?? []).compactMap { event in
            event.asAVFInterstitialEvent(
                with: playerItem,
                sequenceRepeatCount: 1,
				primaryAssetIdentifier: primaryAssetIdentifier,
				queue: queue
            )
        }
    }

    private func scheduleInterstitialEvents() {
        // Schedule interstitial events.
        
        func chooseEvents() -> [AVPlayerInterstitialEvent] {
            // Don't schedule the event if you're inserting periodic interstitials.
            guard !shouldInsertPeriodicInterstitials else {
                return []
            }
            
            return makeInterstitialEventsFromMenuItem()
        }

        let events = chooseEvents()

        // Set interstitial events on event controller.
        guard !events.isEmpty else { return }
        interstitialEventController.events = events
    }
    
    private func makeRandomInterstitialEvent(start: EventStart) -> AVPlayerInterstitialEvent {
        // Randomly create an event from the events list.
        let events = makeInterstitialEventsFromMenuItem()
        let randomEventIndex = Int.random(in: 0..<events.count)
                
        // Create event.
        let chosenRandomEvent = AVPlayerInterstitialEvent(
            identifier: "InterstitialEventScheduledDeltaFromPlayhead-\(start)",
            primaryItem: events[randomEventIndex].primaryItem!,
            start: start,
            interstitialItems: events[randomEventIndex].templateItems,
            restrictions: [],
            resumptionOffset: .invalid,
            playoutLimit: events[randomEventIndex].playoutLimit
        )
        
        // Set random event settings.
        chosenRandomEvent.cue = events[randomEventIndex].cue
        chosenRandomEvent.timelineOccupancy = events[randomEventIndex].timelineOccupancy
        chosenRandomEvent.supplementsPrimaryContent = events[randomEventIndex].supplementsPrimaryContent
        chosenRandomEvent.contentMayVary = events[randomEventIndex].contentMayVary
        chosenRandomEvent.plannedDuration = events[randomEventIndex].plannedDuration
        
        return chosenRandomEvent
    }
    
    // Dynamically schedule an event 30s ahead of the playhead unless one is already present.
    private func schedulePeriodicInterstitialEvent() {
        let nextEventDelta: TimeInterval = 30
        
        let currentTime = integratedTimeline.currentTime
        
        // Check if 30s have passed since the last event's scheduled time.
        let lastEventTime = interstitialEventController.events.last?.time ?? currentTime - nextEventDelta.asCMTime()
        let lastEventWasWithinDelta = CMTimeCompare(lastEventTime, currentTime) >= 0

        guard !lastEventWasWithinDelta else { return }
        let nextEventTime = currentTime.seconds + nextEventDelta
        
        // Make a random interstitial event from menu events list.
        let event = makeRandomInterstitialEvent(start: .time(nextEventTime))

        Logger.general.log("[PlayerState] Inserting periodic interstitial at \(nextEventTime)")
        interstitialEventController.events.append(event)
    }

    // MARK: - Private - Event Observation

    private func beginObservingEvents() {
        // Listen for rate changes.
        NotificationCenter.default
            .publisher(for: AVPlayer.rateDidChangeNotification, object: player)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.playerRateDidChange() }
            .store(in: &subscriptions)
        
        // Listen for integrated timeline snapshot changes.
        NotificationCenter.default
            .publisher(for: AVPlayerItemIntegratedTimeline.snapshotsOutOfSyncNotification, object: integratedTimeline)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.integratedTimelineSnapshotUpdated() }
            .store(in: &subscriptions)
        
        // Check if you need to schedule a periodic event.
        if shouldInsertPeriodicInterstitials {
            Timer.publish(every: 1.0, on: .main, in: .default)
                .autoconnect()
                .sink { [weak self] _ in self?.schedulePeriodicInterstitialEvent() }
                .store(in: &subscriptions)
        }
        
        // Observer for duration.
        durationObservation = self.player.currentItem?.observe(\.duration, changeHandler: { [weak self] item, change in
            guard let self = self else { return }
            // If item duration is indefinite, then the asset is a live stream.
            isPlayingLiveStream = CMTIME_IS_INDEFINITE(item.duration)
        })
        
        // Observer for current integrated timeline time.
        integratedTimelineCurrentTimeTimer = Timer.publish(every: 1.0, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in self?.getCurrentTime() }
    }
    
    private func playerRateDidChange() {
        // Get player rate.
        playerRate = player.rate
    }
    
    private func getCurrentTime() {
        // Get the current integrated timeline time.
		integratedTimelineCurrentTime = CMTimeGetSeconds(integratedTimeline.currentTime)
    }

    private func integratedTimelineSnapshotUpdated() {
        // Get integrated timeline details from snapshot.
        Logger.general.log("[PlayerState] snapshot updated")
        
        // Get integrated timeline segments.
        let integratedTimelineSnapshot = integratedTimeline.currentSnapshot
        let integratedTimelineSegments = integratedTimelineSnapshot.segments
        
        integratedTimelinePointSegments = []
        integratedTimelineFillSegments = []
        
        // Get integrated timeline start time and duration.
        getCurrentTime()
        integratedTimelineStartTime = CMTimeGetSeconds(integratedTimelineSegments.first?.timeMapping.target.start ?? .zero)
        integratedTimelineDuration = (isPlayingLiveStream ?
                                        ( CMTimeGetSeconds(integratedTimelineSegments.last?.timeMapping.target.end ?? .zero) -
                                        integratedTimelineStartTime ) :
                                        CMTimeGetSeconds(integratedTimelineSnapshot.duration))

        // Iterate through integrated timeline segments and get interstitial segments.
        for segment in integratedTimelineSegments where segment.segmentType == AVPlayerItemSegment.SegmentType.interstitial {
            if segment.interstitialEvent?.timelineOccupancy == .singlePoint {
                // Get point occupancy interstitial segments.
                integratedTimelinePointSegments.append(segment)
            } else if segment.interstitialEvent?.timelineOccupancy == .fill {
                // Get fill occupancy intersttitial segments.
                integratedTimelineFillSegments.append(segment)
            }
        }
    }

    // MARK: - Private - SharePlay

    @MainActor
    private func coordinateWithGroupSession() async {
        // Coordinate with SharePlay session.
        guard let sessionBox = await SharePlayCoordinator.shared.unsafeCurrentSession() else {
            Logger.general.error("[PlayerState] Cannot coordinate SharePlay playback without GroupSession")
            return
        }

        player.playbackCoordinator.coordinateWithSession(sessionBox.wrappedValue)
    }

    // MARK: - Public

    func play() {
        // Play with default rate of 1.
        player.play()
    }

    public func setRate(rate: Float) {
        // Set player rate.
        player.rate = rate
    }
        
    func seekOnIntegratedTimeline(to time: TimeInterval, completion: @escaping (Bool) -> Void) {
        // Seek to time (in seconds) on integrated timeline.
    
        var targetTime = time.asCMTime()
        
        // Limit targetTime to be within (integratedStartTime, integratedEndTime).
        let integratedTimelineEndTime = integratedTimelineStartTime + integratedTimelineDuration
        targetTime = CMTimeMinimum(CMTimeMaximum(integratedTimelineStartTime.asCMTime(), targetTime), integratedTimelineEndTime.asCMTime())
        Logger.general.log("Seeking to time \(CMTimeGetSeconds(targetTime))")
        
        // Seek to the target time on the integrated timeline.
        integratedTimeline.seek(
            to: targetTime,
            toleranceBefore: .zero,
			toleranceAfter: .zero,
			completionHandler: { success in
                if success {
                    completion(true)
                }
                self.integratedTimelineCurrentTime = CMTimeGetSeconds(self.integratedTimeline.currentTime)
			})
    }
    
    func seekOnIntegratedTimeline(by delta: TimeInterval, completion: @escaping (Bool) -> Void ) {
        // Seek by delta time (in seconds) on integrated timeline.
        
        let targetTime = integratedTimelineCurrentTime + delta
        seekOnIntegratedTimeline(to: targetTime, completion: { success in
            if success {
                completion(true)
            }
        })
        
    }

    func invalidate() {
        // Clean up the player state.
        let identifier = menuItem.id

        durationObservation?.invalidate()
        durationObservation = nil

        Task { @MainActor in
            Logger.general.info("[PlayerState] Releasing playback item with identifier \(identifier)")
            subscriptions.forEach { $0.cancel() }
            player.replaceCurrentItem(with: nil)
            await SharePlayCoordinator.shared.tearDown()
        }
    }
}

