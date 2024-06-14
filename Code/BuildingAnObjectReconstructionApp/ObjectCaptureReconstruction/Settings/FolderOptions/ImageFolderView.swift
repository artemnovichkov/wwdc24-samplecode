/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Choose the image folder.
*/

import SwiftUI
import RealityKit
import os

private let logger = Logger(subsystem: ObjectCaptureReconstructionApp.subsystem,
                            category: "ImageFolderView")

struct ImageFolderView: View {
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel

    @State private var showFileImporter = false
    @State private var selectedFolder: URL?
    @State private var numImages: Int?
    @State private var thumbnailURLs: [URL]?
    @State private var metadataAvailability = ImageHelper.MetadataAvailability()
    @State private var showInfo = false
    static private let numThumbnailsToDisplay = 5

    var body: some View {
        LabeledContent("Image Folder:") {
            VStack(spacing: 6) {
                HStack {
                    Text(title).foregroundStyle(.secondary).font(.caption)
                    
                    Spacer()
                    
                    if metadataAvailability.gravity && metadataAvailability.depth {
                        Button {
                            showInfo = true
                        } label: {
                            Image(systemName: "photo.badge.checkmark")
                                .foregroundColor(.green)
                                .frame(height: 15)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showInfo) {
                            VStack(alignment: .leading) {
                                Text("Image Metadata Found")
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 7)
                                
                                Divider()
                                
                                Text("Depth and Gravity Vector included in dataset.")
                                    .padding([.horizontal, .bottom])
                            }
                            .font(.callout)
                            .frame(width: 250)
                        }
                    }
                    if selectedFolder != nil {
                        Button {
                            selectedFolder = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .frame(height: 15)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding([.leading, .trailing], 6)
                .padding(.top, 3)
                .frame(height: 20)
                
                Divider()
                    .padding(.top, -4)
                    .padding(.horizontal, 6)
                
                HStack {
                    if let thumbnailURLs {
                        ForEach(thumbnailURLs, id: \.self) { thumbnailURL in
                            ThumbnailView(imageFolderURL: thumbnailURL)
                                .frame(width: 45, height: 45)
                        }
                    } else {
                        Image(systemName: "folder")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(height: 35)
                
                Button {
                    showFileImporter.toggle()
                } label: {
                    HStack {
                        if let selectedFolder = selectedFolder {
                            HStack {
                                Image(nsImage: NSWorkspace.shared.icon(for: .folder))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                
                                Text("\(selectedFolder.lastPathComponent)")
                            }
                        } else {
                            Text("Choose...")
                        }
                        Spacer()
                    }
                }
                .padding(6)
                .task(id: selectedFolder) {
                    guard let selectedFolder else {
                        numImages = nil
                        thumbnailURLs = nil
                        metadataAvailability = ImageHelper.MetadataAvailability()
                        appDataModel.boundingBoxAvailable = false
                        return
                    }

                    let imageURLs = ImageHelper.getListOfURLs(from: selectedFolder)
                    if imageURLs.isEmpty {
                        appDataModel.state = .error
                        appDataModel.alertMessage = "\(String(describing: PhotogrammetrySession.Error.invalidImages(selectedFolder)))"
                        self.selectedFolder = nil
                        return
                    }

                    numImages = imageURLs.count

                    // Pick 5 images to display.
                    if numImages! < Self.numThumbnailsToDisplay {
                        thumbnailURLs = imageURLs
                    } else {
                        let step = numImages! / Self.numThumbnailsToDisplay
                        let filteredIndices = imageURLs.indices.filter { $0 % step == 0 }[0..<Self.numThumbnailsToDisplay]
                        thumbnailURLs = filteredIndices.map { imageURLs[$0] }
                    }

                    // Check whether enough metadata is available.
                    metadataAvailability = await ImageHelper.getMetadataAvailability(for: imageURLs)
                    appDataModel.boundingBoxAvailable = metadataAvailability.boundingBox
                }
                .fileImporter(isPresented: $showFileImporter,
                              allowedContentTypes: [.folder]) { result in
                    switch result {
                    case .success(let directory):
                        let gotAccess = directory.startAccessingSecurityScopedResource()
                        if !gotAccess { return }
                        selectedFolder = directory
                    case .failure(let error):
                        appDataModel.alertMessage = "\(error)"
                        appDataModel.state = .error
                    }
                }
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .onAppear {
                selectedFolder = appDataModel.imageFolder
            }
            .onChange(of: selectedFolder) {
                appDataModel.boundingBoxAvailable = false
                metadataAvailability = ImageHelper.MetadataAvailability()
                appDataModel.imageFolder = selectedFolder
            }
            .dropDestination(for: URL.self) { items, location in
                guard !items.isEmpty else { return false }
                var isDirectory: ObjCBool = false
                if let url = items.first,
                   FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
                   isDirectory.boolValue == true {
                    selectedFolder = url
                    return true
                }
                logger.info("Dragged item is not a folder!")
                return false
            }
        }
        .frame(height: 110)
    }

    private var title: String {
        if let numImages = numImages {
            return "\(numImages) Images"
        } else {
            return "Drag in a folder of Images"
        }
    }
}
