/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows content shelves in a vertical stack below a header view.
*/

import SwiftUI

/// The `StackView` implements an example landing page for a content catalog
/// app.
///
/// It defines several shelves with a showcase or hero header area above them.
/// The view defines its header area using a `.containerRelativeFrame`, taking
/// up 80% of its own container's vertical space, and defines a
/// `.focusSection()` so that its full width can act as a target for focus
/// movement, which it then diverts to its content.  Otherwise, moving focus up
/// from the right side of the shelves below might fail, or might jump all the
/// way to the tab bar.
///
/// This view also defines an above/below fold appearance in concert with its
/// background view.  When above the fold, its background renders a material
/// gradient toward the bottom of the screen.  When focus moves downward enough
/// to roll the header area offscreen, the view snaps down to the first row of
/// shelves and the background material grows to cover the entire image,
/// softening the background without entirely abandoning the header's
/// coloration.
struct StackView: View {
    @State private var belowFold = false
    private var showcaseHeight: CGFloat = 800

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 26) {
                    // The header/showcase view.
                    VStack(alignment: .leading) {
                        Text("tvOS with SwiftUI")
                            .font(.largeTitle).bold()

                        Spacer()

                        HStack {
                            Button("Show") {}
                            NavigationLink("More Info…") {
                                Text("Hello")
                            }
                        }
                        .padding(.bottom, 80)
                    }
                    // Stretch the trailing edge to the width of the screen.
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // Then place a focus target over that entire area.
                    .focusSection()
                    // Use 80% of the container's vertical space.
                    .containerRelativeFrame(.vertical, alignment: .topLeading) {
                        length, _ in length * 0.8
                    }
                    .onScrollVisibilityChange { visible in
                        // When the header scrolls more than 50% offscreen,
                        // toggle to the below-the-fold state.
                        withAnimation {
                            belowFold = !visible
                        }
                    }

                    Section("Movie Shelf") {
                        MovieShelf()
                    }

                    Section("TV and Music Shelf") {
                        TVMusicShelf()
                    }

                    Section("Content Cards") {
                        CardShelf()
                    }
                }
                // Use this vertical stack's content views to determine scroll
                // targeting.
                .scrollTargetLayout()
            }
            .background(alignment: .top) {
                // Draw the background, which changes when the view moves below
                // the fold.
                HeroHeaderView(belowFold: belowFold)
            }
            .scrollTargetBehavior(
                // This is a custom scroll target behavior that uses the
                // expected height of the showcase view.
                FoldSnappingScrollTargetBehavior(
                    aboveFold: !belowFold, showcaseHeight: showcaseHeight))
            // Disable scroll clipping so the scroll view doesn't clip the
            // raised focus effects.
            .scrollClipDisabled()
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
}

/// Implements an above- or below-the-fold snapping behavior.
///
/// This behavior uses the expected height of the header to determine the
/// snapping behavior, depending on whether the view is currently above the fold
/// (showing the header) or below (showing only the shelves).  When a scroll
/// event moves the scroll view's content bounds beyond a certain threshold, it
/// changes the target of the scroll so that it either snaps to the top of the
/// scroll view, or snaps to a point below the header.
struct FoldSnappingScrollTargetBehavior: ScrollTargetBehavior {
    var aboveFold: Bool
    var showcaseHeight: CGFloat

    /// This takes a `ScrollTarget` that contains the proposed end point of
    /// the current scroll event.  In tvOS, this is the target of a scroll
    /// that the focus engine triggers when attempting to bring a newly focused
    /// item into view.
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        // If the current scroll offset is near the top of the view and the
        // target is not lower than 30% of the header's height, all is good.
        // This allows a little flexibility when moving toward any buttons that
        // might be part of the header view.
        if aboveFold && target.rect.minY < showcaseHeight * 0.3 {
            // The target isn't moving enough to pass the snap point.
            return
        }

        // If the header isn't visible and the target isn't high enough to
        // reveal any of the header, the scroll can land anywhere the system
        // determines within this area.
        if !aboveFold && target.rect.minY > showcaseHeight {
            // The target isn't far enough up to reveal the showcase.
            return
        }

        // The view needs to snap upward to reveal the header only if the
        // target is more than 30% of the way up from the bottom edge of the
        // showcase.
        let showcaseRevealThreshold = showcaseHeight * 0.7

        // If the target of the scroll is anywhere between the header's bottom
        // edge and that threshold, the view needs to snap to hide the header.
        let snapToHideRange = showcaseRevealThreshold...showcaseHeight

        if aboveFold || snapToHideRange.contains(target.rect.origin.y) {
            // The view is either above the fold and scrolling more than 30% of
            // the way down, or it's below the fold and isn't moving up far
            // enough to reveal the showcase.

            // This case likely triggers every time you move focus among the
            // items on the top content shelf, as the focus system brings them a
            // little farther onto the screen.  It's very likely that this code
            // is setting the target origin to it's current position here,
            // effectively denying any scrolling at all.
            target.rect.origin.y = showcaseHeight
        }
        else {
            // The view is below the fold and it's moving up beyond the bottom
            // 30% of the header view.  Snap to the view's origin to reveal the
            // entire header.
            target.rect.origin.y = 0
        }
    }
}

#Preview {
    StackView()
}
