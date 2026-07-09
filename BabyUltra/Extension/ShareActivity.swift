//
//  ShareActivity.swift
//  BabyUltra
//
//  Created by Ozgur Ulukan on 11/07/24.
//

import SwiftUI

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    class Coordinator: NSObject, UIPopoverPresentationControllerDelegate {
        func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
            guard let view = popoverPresentationController.presentedViewController.view else { return }
            popoverPresentationController.sourceView = view
            popoverPresentationController.sourceRect = view.bounds
            popoverPresentationController.permittedArrowDirections = []
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.delegate = context.coordinator
        }
        return activityViewController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
