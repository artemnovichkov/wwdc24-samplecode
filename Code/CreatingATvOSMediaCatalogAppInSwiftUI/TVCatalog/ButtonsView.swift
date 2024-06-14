/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows button style options.
*/

import SwiftUI

/// The `ButtonsView` provides a showcase of the various button styles available
/// in tvOS.
///
/// Of these, only the `.card` style is unique to Apple TV.  You can
/// adjust each style using the `.buttonBorderShape()` modifier, though it
/// affects the various styles differently.
///
/// Try adding an accent color to the app's asset catalog and see how each
/// button style uses it.
struct ButtonsView: View {
    var body: some View {
        ScrollView(.vertical) {
            // Bordered buttons, the default platter-backed button style.
            HStack {
                Button("Bordered") {}
                Button("Bordered") {}
                    .buttonBorderShape(.capsule)
                Button {} label: {
                    Image(systemName: "movieclapper")
                }
                .buttonBorderShape(.circle)
            }

            Divider()

            // The default bordered button style, but this time with an
            // applied `.tint()`.  This provides exactly the same behavior as
            // iOS.
            HStack {
                Button("Bordered (tint)") {}
                Button("Bordered (tint)") {}
                    .buttonBorderShape(.capsule)
                Button {} label: {
                    Image(systemName: "movieclapper")
                }
                .buttonBorderShape(.circle)
            }
            .tint(.blue)

            Divider()

            // The `.borderedProminent` style behaves exactly like `.bordered`
            // unless you add a tint.  The system uses the tint color for
            // the button's unfocused platter for a more prominent appearance.
            // This provides the same appearance here as in iOS.
            HStack {
                Button("Prominent") {}
                Button("Prominent") {}
                    .buttonBorderShape(.capsule)
                Button {} label: {
                    Image(systemName: "movieclapper")
                }
                .buttonBorderShape(.circle)
            }
            .tint(.blue)
            .buttonStyle(.borderedProminent)

            Divider()

            /// The `.plain` button style behaves like a bordered button that
            /// has no platter until it receives focus. It appears to be just a
            /// text view until focus moves to it, at which point it lifts and
            /// gains a white platter.  You can use this for a truncated
            /// description, where you click it to see a complete description
            /// in a full-screen overlay.
            HStack {
                Button("Plain") {}
                Button {} label: {
                    Label("Labeled", systemImage: "movieclapper")
                }
                Button {} label: {
                    Image(systemName: "movieclapper")
                }
                .buttonBorderShape(.circle)
            }
            .buttonStyle(.plain)

            Divider()

            // Borderless buttons locate the first `Image` instance within their
            // labels and apply the `.highlight` hover effect to that image.
            // They also apply a rounded-rectangle clipping shape to the image.
            //
            // The `.highlight` hover effect lifts its content when it has
            // focus, scaling it up and providing a drop shadow.  It also places
            // a specular highlight on its content, and tilts as if on a motion
            // gimbal as you drag your finger across the touch surface of the
            // Siri Remote.
            HStack {
                Button {} label: {
                    Image("discovery_portrait")
                        .resizable()
                        .frame(width: 250, height: 375)
                    Text("Borderless Portrait")
                }

                Button {} label: {
                    Image("discovery_landscape")
                        .resizable()
                        .frame(width: 400, height: 240)
                    Text("Borderless Landscape")
                }

                // If your button doesn't contain an `Image` instance, or if it
                // contains more than one and you want the highlight effect to
                // apply to something other than the first instance, you can tag
                // any view manually with `.hoverEffect(.highlight)` to make it
                // the focus of the button's hover effect.
                Button {} label: {
                    CodeSampleArtwork(size: .appIconSize)
                        .frame(width: 400, height: 240)
                        .hoverEffect(.highlight)
                    Text("Custom Icon View")
                }

                // Applying a button border shape on a borderless button changes
                // the clipping shape to use for the highlighted image. The most
                // common occurrence of this is in the cast/crew lockups at the
                // bottom of a movie page on the Apple TV app, where the app
                // clips the image to a circle.
                Button {} label: {
                    Image(systemName: "person.circle")
                        .font(.title)
                        .background(Color.blue.grayscale(0.7))
                        // Places the effect on the image *and* its background.
                        .hoverEffect(.highlight)
                    Text("Shaped")
                }
                .buttonBorderShape(.circle)
            }
            .buttonStyle(.borderless)

            Divider()

            // The `.card` modifier provides a rounded rectangle clip shape by
            // default, and draws a platter behind its content with no applied
            // padding.  This means that a `.card` button containing an image
            // is just that image with the corresponding clip shape and focus
            // behavior.
            //
            // When the button has focus, the content and platter grow, and the
            // platter becomes a little lighter and more opaque, though not as
            // much as the `.bordered` button style. The style provides a motion
            // effect that derives from the Siri Remote's touch surface, which
            // adjusts the button's offset on the x and y axes without any 3D
            // tilt effects.
            VStack {
                HStack {
                    // Because the style doesn't apply padding by default (as it
                    // does with bordered buttons), a plain label in a card
                    // button has a platter that fits tightly around the label.
                    Button {} label: {
                        Label("A Card Button", systemImage: "button.horizontal")
                    }

                    // A card button containing an image doesn't have a visible
                    // platter because the image covers it unless you mask it or
                    // clip it independently of the button.
                    Button {} label: {
                        Image("discovery_landscape")
                            .resizable()
                            .frame(width: 400, height: 240)
                            .overlay(alignment: .bottom) {
                                Text("Image Card")
                            }
                    }

                    // Placing text below the image reveals the platter.
                    Button {} label: {
                        VStack {
                            Image("discovery_landscape")
                                .resizable()
                                .frame(width: 400, height: 240)
                            Text("Vertical Card")
                        }
                    }
                }

                HStack {
                    // Applying some padding to the button's label creates an
                    // effect more like the Apple TV app's search results, with
                    // the content inset within the platter.
                    Button {} label: {
                        VStack {
                            Image("discovery_landscape")
                                .resizable()
                                .frame(width: 400, height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Text("Inset Card")
                        }
                        .padding(20)
                    }

                    // Setting the button border shape clips the entire card button,
                    // including the platter and content.
                    Button {} label: {
                        VStack {
                            Image("discovery_landscape")
                                .resizable()
                                .frame(width: 400, height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Text("Circle Card")
                        }
                        .padding(20)
                    }
                    .buttonBorderShape(.circle)
                }
            }
            .buttonStyle(.card)

            Divider()

            // The card button style can be a good starting point for building
            // your own content lockups.  The style simply displays its content
            // with a clip shape and background, and nothing else.  This makes
            // it work particularly well when pairing it with a custom label
            // style, such as the `CardOverlayLabelStyle`.
            HStack {
                // A simple implementation with a single textual title.
                Button {} label: {
                    Label {
                        Text("Title at the bottom")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image("discovery_landscape")
                            .resizable()
                            .aspectRatio(400 / 240, contentMode: .fit)
                    }
                }
                .frame(maxWidth: 400)

                // An example with a more complex label that places titles at
                // the top and bottom of the resulting lockup.
                Button {} label: {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title at the top")
                                .font(.body.bold())
                            Text("Some subtitle text as well")
                                .font(.caption)

                            Spacer()

                            Text("Additional info at the bottom")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image("discovery_landscape")
                            .resizable()
                            .aspectRatio(400 / 240, contentMode: .fit)
                    }
                }
                .frame(maxWidth: 400)
            }
            .buttonStyle(.card)
            .labelStyle(CardOverlayLabelStyle())
        }
    }
}

/// Implements a custom card lockup label style.
///
/// This style takes the label's icon and uses it as a backdrop for its title.
/// It overlays a subtle gradient on the icon to darken it toward the bottom,
/// along with a 2 pt stroke, which it effectively transforms into a 1 pt
/// inner-stroke when combining it with the card button's matching button border
/// shape's clipping region.
///
/// The style then places the label's title on top of the icon, with a little
/// padding. The surrounding `ZStack` uses `.bottomLeading` alignment, so the
/// title aligns toward the lower corner by default.
struct CardOverlayLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .bottomLeading) {
            configuration.icon
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.6), location: 0.1),
                            .init(color: .black.opacity(0.2), location: 0.25),
                            .init(color: .black.opacity(0), location: 0.4)
                        ],
                        startPoint: .bottom, endPoint: .top
                    )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(lineWidth: 2)
                        .foregroundStyle(.quaternary)
                }

            configuration.title
                .padding(6)
        }
    }
}

#Preview {
    ButtonsView()
}
