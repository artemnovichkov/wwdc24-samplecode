/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for modifying alert information for a particular contact.
*/

import SwiftUI
import SwiftData

/// The entry point for the trips view tab. Provides a list of editable beach
/// trips that can be created by the app of the widget process a shared
/// `TripRouter` navigation coordinator.
struct TripsView: View {
    @Query(sort: \Trip.date, order: .reverse) private var trips: [Trip]
    @Bindable private var router = TripRouter.shared
    @Environment(\.self) private var environment
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            SidebarView(trips: trips, selectedTrip: $router.selectedTrip)
                .frame(minWidth: 245)
        } detail: {
            if let selectedTrip = router.selectedTrip {
                TripDetailsView(trip: selectedTrip)
            } else {
                Text("Select a Trip")
                    .navigationTitle("Trips")
            }
        }
        .onChange(of: router.compositionRequested) { oldValue, newValue in
            guard newValue != oldValue else { return }
            router.createComposition(in: environment, for: modelContext)
        }
    }
}

// MARK: Details View

private struct TripDetailsView: View {
    let trip: Trip
    @State private var currentEditingContact: Contact?
    @Environment(\.modelContext) private var modelContext

    private var sortedComments: [Comment] {
        trip.comments.sorted { $0.contact < $1.contact }
    }

    var body: some View {
        ScrollView {
            Group {
                TripPostView(trip: trip)
                    .modifier(CenteredListItemModifier())
                ForEach(sortedComments) { comment in
                    TripCommentView(comment: comment)
                        // Contain the comment view element so the replies to a
                        // comment don't become combined with the primary comment
                        // in the view.
                        .accessibilityElement(children: .contain)
                        .modifier(CenteredListItemModifier())
                        .contextMenu {
                            Button("Edit Alerts") {
                                editAlerts(for: comment.contact)
                            }
                        }
                        // Provide the delete button for quicker access as a custom action.
                        .accessibilityAction(named: "Edit Alerts") {
                            editAlerts(for: comment.contact)
                        }
                        .onDisappear {
                            comment.isUnread = false
                        }
                }
            }
        }
        .frame(minWidth: 400)
        .scrollContentBackground(.hidden)
        // Label the containing scroll view for the container rotor on iOS
        // or the ScrollView container element on macOS.
        .accessibilityLabel(trip.title)
        .navigationTitle(trip.title)
        .sheet(item: $currentEditingContact) { contact in
            ContactAlertView(contact: contact)
        }
        .toolbar {
            ShareLink(
                item: Image(trip.image),
                preview: SharePreview(trip.title, image: Image(trip.image))
            ) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share Trip")
        }
    }

    private func editAlerts(for name: String) {
        let descriptor = FetchDescriptor(predicate: #Predicate<Contact> {
            $0.name == name
        })
        guard let result = try? modelContext.fetch(descriptor) else {
            return
        }
        if result.count > 1 {
            currentEditingContact = result[0]
        } else {
            let contact = Contact(name: name, alert: [])
            modelContext.insert(contact)
            try? modelContext.save()
            currentEditingContact = contact
        }
    }
}

private struct TripPostView: View {
    let trip: Trip
    @State private var overlayOpacity = 0.0

    var body: some View {
        VStack(alignment: .center) {
            LabeledContent {
                Image(decorative: trip.image)
                    .resizable()
            } label: {
                Text(trip.message)
            }
            .labeledContentStyle(PostLabeledContentStyle(
                postConfiguration: .init(
                    date: trip.date, color: trip.color.color)))
            .accessibilityLabel { label in
                // Append the rating so the hover overlay doesn't need to
                // appear for accessibility to prioritize announcing the rating.
                if let rating = trip.rating {
                    Text(rating.label)
                }
                label
            }
            .accessibilityActions {
                // Allow clients such as VoiceOver to activate attachments without
                // invoking the hoverable overlay for quicker access.
                AttachmentOverlayView(trip: trip, opacity: 1.0)
            }
            .accessibilityAddTraits(.isImage)
            .frame(maxWidth: 700)
            .overlay(alignment: .top) {
                AttachmentOverlayView(trip: trip, opacity: overlayOpacity)
            }
            .onTapGesture {
                toggleOverlay(overlayOpacity == 0.0)
            }
            .onHover { isHovering in
                toggleOverlay(isHovering)
            }

            Divider()
                .padding(.top)
                .frame(maxWidth: 800)
        }
        .padding(10)
    }

    private func toggleOverlay(_ isEnabled: Bool) {
        withAnimation(.easeInOut(duration: 0.25)) {
            overlayOpacity = isEnabled ? 1.0 : 0
        }
    }
}

private struct AttachmentOverlayView: View {
    let trip: Trip
    let opacity: Double
    @Environment(\.openURL) private var openURL

    private var attachmentConfiguration: TripAttachmentConfiguration {
        .init(urlAction: openURL)
    }

    var body: some View {
        HStack {
            ForEach(trip.makeAttachments(with: attachmentConfiguration), id: \.id) { attachment in
                Button {
                    attachment.performAction()
                } label: {
                    AttachmentImage(
                        image: attachment.imageName, color: attachment.color)
                    .accessibilityLabel(attachment.label)
                }
                .buttonStyle(.borderless)
            }
            if let rating = trip.rating {
                // Make the attachment image and shape a single accessibility element.
                AttachmentImage(
                    image: rating.imageName, color: .orange, supportsHover: false)
                    .accessibilityElement()
                    .accessibilityLabel(rating.label)
            }
        }
        .frame(height: 50)
        .padding(.horizontal)
        .background {
            Capsule()
                .foregroundStyle(.background)
                .shadow(radius: 10)
        }
        .opacity(opacity)
        .disabled(opacity == 0.0)
        .offset(y: 20)
    }
}

private struct AttachmentImage: View {
    var image: String
    var color: Color
    var supportsHover: Bool = true
    @State private var mixAmount = 0.0

    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(color.mix(with: .black, by: mixAmount))
                .shadow(radius: 2)
            Image(systemName: image)
                .foregroundStyle(.white)
                .bold()
        }
        .frame(width: 35, height: 35)
        .onHover { isHovering in
            guard supportsHover else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                mixAmount = isHovering ? 0.1 : 0
            }
        }
    }
}

private struct TripCommentView: View {
    private static let favoriteColor = Color.yellow.mix(with: .orange, by: 0.15)
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading) {
            LabeledContent {
                CommentMessageView {
                    UnreadIndicatorView(isUnread: comment.isUnread)
                } title: {
                    Text(comment.message)
                }

                Spacer()

                Button(action: toggleFavorite) {
                    let label = comment.reaction.label ?? .init()
                    Image(systemName: comment.reaction.image)
                        .bold(comment.reaction == .superFavorite)
                        .foregroundStyle(Self.favoriteColor)
                        .symbolEffect(.bounce, value: comment.reaction)
                        // Provide a custom label for the modifier only when the model provides one.
                        // Otherwise default to the current label.
                        .accessibilityLabel(label, isEnabled: !label.isEmpty)
                }
                .buttonStyle(.borderless)

                Button(action: createReply) {
                    Image(systemName: "arrowshape.turn.up.left")
                }
                .buttonStyle(.borderless)
            } label: {
                Text(comment.contact)
            }
            .labeledContentStyle(CommentLabeledContentStyle())
            // Ensure the comment is the first item focused by clients like VoiceOver.
            .accessibilitySortPriority(2)

            ForEach(comment.replies) { reply in
                Text(reply.message)
                    .modifier(CommentModifier(style: .quaternary))
                    .padding(.leading, 30)
            }
        }
        .frame(maxWidth: 700, alignment: .center)
    }

    private func toggleFavorite() {
        switch comment.reaction {
        case .none:
            comment.reaction = .favorite
        case .favorite:
            comment.reaction = .superFavorite
        case .superFavorite:
            comment.reaction = .none
        }
    }

    private func createReply() {
        Comment.makeReply(for: comment).map {
            var replies = comment.replies
            replies.append($0)
            comment.replies = replies
        }
    }
}

private struct UnreadIndicatorView: View {
    var isUnread: Bool

    var body: some View {
        Circle()
            // Conditionally apply an "Unread" label here for when the indicator
            // becomes combined within its parent view so "Unread" is only appended
            // to the parent view element when the view is actually unread.
            .accessibilityLabel("Unread", isEnabled: isUnread)
            .opacity(isUnread ? 1.0 : 0.0)
    }
}

// MARK: Sidebar

private struct SidebarView: View {
    let trips: [Trip]
    @Binding var selectedTrip: Trip?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List(selection: $selectedTrip) {
            ForEach(trips, id: \.self) { trip in
                TripItemView(trip: trip)
                    #if os(macOS)
                    .contextMenu {
                        Button("Delete") {
                            modelContext.delete(trip)
                            try? modelContext.save()
                        }
                    }
                    #endif
            }
            .onDelete {
                $0.forEach {
                    modelContext.delete(trips[$0])
                    try? modelContext.save()
                }
            }
        }
        .navigationTitle("Trips")
        .toolbar {
            TripComposerItem()
        }
    }
}

private struct TripItemView: View {
    let trip: Trip

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .foregroundStyle(trip.color.color)
                Image(systemName: trip.icon)
            }
            .frame(idealWidth: 30, idealHeight: 30)
            // Hide the trip icon so its symbol content is not concatenated
            // during an accessibility element combine.
            .accessibilityHidden(true)

            Text(trip.title)
                .bold()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct TripComposerItem: View {
    @Environment(\.self) private var environment
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button(action: createNewTrip) {
            Image(systemName: "square.and.pencil")
        }
        .accessibilityLabel("New Trip")
    }

    private func createNewTrip() {
        modelContext.insert(Trip.makeTrip(in: environment))
    }
}
