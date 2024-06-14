/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows an example of a content product page with an expandable text description.
*/

import SwiftUI

let loremIpsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. In hac habitasse platea dictumst vestibulum rhoncus est pellentesque elit. Id cursus metus aliquam eleifend. Sem et tortor consequat id porta nibh venenatis cras sed. Volutpat commodo sed egestas egestas fringilla phasellus faucibus scelerisque eleifend. Tincidunt eget nullam non nisi est sit amet facilisis magna. Etiam sit amet nisl purus in mollis nunc sed id. Proin nibh nisl condimentum id venenatis. Etiam erat velit scelerisque in. Ultricies leo integer malesuada nunc vel risus. Sed lectus vestibulum mattis ullamcorper velit sed. Turpis tincidunt id aliquet risus feugiat in. Volutpat diam ut venenatis tellus. Tortor consequat id porta nibh venenatis cras sed felis. Vulputate eu scelerisque felis imperdiet proin. Viverra tellus in hac habitasse platea dictumst vestibulum rhoncus est. Pharetra et ultrices neque ornare aenean. Curabitur vitae nunc sed velit dignissim sodales ut."

/// The `DescriptionView` provides an example of how to build a product page
/// similar to those you see on the Apple TV app.
///
/// It provides a background image with a custom material gradient overlay that
/// adds a blur behind the title and interactive content.  It also places a
/// title at the top of the view, and labels and controls at the bottom.
struct DescriptionView: View {
    @State var showDescription = false

    var body: some View {
        VStack(alignment: .leading) {
            Text("Title")
                .font(.largeTitle)
                .bold()

            Spacer()

            VStack(spacing: 12) {
                Text("Signup information")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(alignment: .top, spacing: 30) {
                    // The three buttons each need to be the same width.  To
                    // achieve this, their labels use
                    // `.frame(maxWidth: .infinity)`.  It's important to place
                    // this modifier on the label rather than on the button
                    // because the button is simply the label with some padding
                    // and a background.  This means that the button's platter
                    // doesn't extend beyond its label farther than its static
                    // padding amount, so the view stretches the label in the
                    // required axis.  The default alignment of a max-width
                    // frame is `.center`, so the text remains centered inside
                    // the button.
                    VStack(spacing: 12) {
                        Button {} label: {
                            Text("Sign Up")
                                .font(.body.bold())
                                .frame(maxWidth: .infinity)
                        }

                        Button {} label: {
                            Text("Buy or Rent")
                                .font(.body.bold())
                                .frame(maxWidth: .infinity)
                        }

                        Button {} label: {
                            Label("Add to Up Next", systemImage: "plus")
                                .font(.body.bold())
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // The view presents the description using the `.plain`
                    // button style, which renders only its label until it
                    // receives focus.  The `.lineLimit` modifier truncates the
                    // content, and when someone presses the button, a
                    // `.fullScreenCover` presents the entire description.
                    Button {
                        showDescription = true
                    } label: {
                        Text(loremIpsum)
                            .font(.callout)
                            .lineLimit(5)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 1000)

                    // If you want to have flowing text with different
                    // attributes on different words, you can use either an
                    // `AttributedString` or, for simplicity, add some `Text`
                    // views together.
                    VStack(spacing: 0) {
                        Text("Starring")
                            .foregroundStyle(.secondary) + Text(" Stars, Costars, and Extras")
                        Text("Director")
                            .foregroundStyle(.secondary) + Text(" Someone Great")
                    }
                }
            }
            .padding(.top)
        }
        .background {
            Asset.beach.landscapeImage
                .aspectRatio(contentMode: .fill)
                .overlay {
                    // Provide a material gradient by filling an area with
                    // the chosen material and then applying a mask to that
                    // area. Adjust opacity of the material to reveal the
                    // image while providing a blurred backing to any overlaid
                    // text.
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .mask {
                            LinearGradient(
                                stops: [
                                    .init(color: .white, location: 0.2),
                                    .init(color: .white.opacity(0.7), location: 0.4),
                                    .init(color: .white.opacity(0), location: 0.56),
                                    .init(color: .white.opacity(0), location: 0.7),
                                    .init(color: .white.opacity(0.25), location: 0.8)
                                ],
                                startPoint: .bottom, endPoint: .top
                            )
                        }
                }
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showDescription) {
            VStack(alignment: .center) {
                Text(loremIpsum)
                    .frame(maxWidth: 600)
            }
        }
    }
}

#Preview {
    DescriptionView()
}
