/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Examples for using scroll transitions for a view.
*/

import SwiftUI

#Preview("Paging + Parallax") {
    let photos = [
        Photo("Lily Pads"),
        Photo("Fish"),
        Photo("Succulent")
    ]
    
    ScrollView(.horizontal) {
        LazyHStack(spacing: 16) {
            ForEach(photos) { photo in
                VStack {
                    ZStack {
                        ItemPhoto(photo)
                            .scrollTransition(axis: .horizontal) { content, phase in
                                content
                                    .offset(x: phase.isIdentity ? 0 : phase.value * -200)
                            }
                    }
                    .containerRelativeFrame(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    
                    ItemLabel(photo)
                        .scrollTransition(axis: .horizontal) { content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : 0)
                                .offset(x: phase.value * 100)
                        }
                    
                }
            }
        }
    }
    .contentMargins(32)
    .scrollTargetBehavior(.paging)
    
}

#Preview("Paging + Rotation") {
    let photos = [
        Photo("Lily Pads"),
        Photo("Fish"),
        Photo("Succulent")
    ]

    ScrollView(.horizontal) {
        LazyHStack(spacing: 12) {
            ForEach(photos) { photo in
                ItemPhoto(photo)
                    .containerRelativeFrame(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .scrollTransition(axis: .horizontal) { content, phase in
                        content
                            .rotationEffect(.degrees(phase.value * 1.5))
                    }
            }
        }
    }
    .contentMargins(24)
    .scrollTargetBehavior(.paging)
}

#Preview("Paging") {
    let photos = [
        Photo("Lily Pads"),
        Photo("Fish"),
        Photo("Succulent")
    ]

    ScrollView(.horizontal) {
        LazyHStack(spacing: 12) {
            ForEach(photos) { photo in
                ItemPhoto(photo)
                    .containerRelativeFrame(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 36))
            }
        }
    }
    .contentMargins(24)
    .scrollTargetBehavior(.paging)
}

struct Photo: Identifiable {
    var title: String

    var id: Int = .random(in: 0 ... 100)

    init(_ title: String) {
        self.title = title
    }
}

struct ItemPhoto: View {
    var photo: Photo

    init(_ photo: Photo) {
        self.photo = photo
    }

    var body: some View {
        Image(photo.title)
            .resizable()
            .scaledToFill()
            .frame(height: 500)
    }
}

struct ItemLabel: View {
    var photo: Photo

    init(_ photo: Photo) {
        self.photo = photo
    }

    var body: some View {
        Text(photo.title)
            .font(.title)
    }
}

