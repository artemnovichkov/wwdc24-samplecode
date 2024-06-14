/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom model presentation view for presenting content.
*/
import Foundation
import SwiftUI

extension View {

    // Extend the view with a custom presentation.
    func modalPresentationCoordinated() -> some View {
        modifier(ModalPresentationCoordinator.ModalPresentationCoordViewModifier())
    }
}

@Observable
class ModalPresentationCoordinator {

    static var shared = ModalPresentationCoordinator()

    // Set property for a modal presentation.
    fileprivate var presentation: ModalPresentation? {
        willSet {
            guard let dismiss = presentation?.onDismiss else { return }
            dismiss()
        }
    }
    
    // Create a view from content on request.
    @MainActor
    func requestPresentation(@ViewBuilder content: @escaping () -> some View, onDismiss: @escaping () -> Void = {}) {
        presentation = .init(content: AnyView(content()), onDismiss: onDismiss)
    }

    @MainActor
    func dismissModalView() {
        presentation = nil
    }
}

extension ModalPresentationCoordinator {

    // The modal presentation object.
    struct ModalPresentation: Identifiable {
        let id = UUID()
        let content: AnyView
        let onDismiss: () -> Void
    }
}

extension ModalPresentationCoordinator {

    // Specify the modified body view for the modal presentation.
    fileprivate struct ModalPresentationCoordViewModifier: ViewModifier {
        @Bindable var modalPresentationCoordinator = ModalPresentationCoordinator.shared

        func body(content: Content) -> some View {
            content.fullScreenCover(item: $modalPresentationCoordinator.presentation) { presentation in
                presentation.content
            }
        }
    }
}
