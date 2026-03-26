//
//  ActionsTabView.swift
//  TweakItExample
//
//  Custom tab demonstrating programmatic panel dismissal.
//  The "Present Alert" button calls SwiftUI's dismiss() then presents
//  a UIAlertController — the exact flow that requires the panel window
//  to hide itself after programmatic dismissal.
//

import SwiftUI
import TweakIt

struct ActionsTabView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Dismiss & Present") {
                Button {
                    dismiss()
                    // Present an alert on the key window after the panel dismisses.
                    // Without the KVO fix, the hidden-but-still-blocking panel window
                    // would swallow all touches on this alert.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentAlert()
                    }
                } label: {
                    Label("Present Alert", systemImage: "exclamationmark.bubble")
                }
            }

            Section("Presets") {
                Button {
                    DemoTweaks.store.storage.resetAll()
                } label: {
                    Label("Reset All to Defaults", systemImage: "arrow.counterclockwise")
                }
            }
        }
    }

    private func presentAlert() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        // Walk to the topmost presented VC so the alert isn't behind anything.
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        let alert = UIAlertController(
            title: "It works!",
            message: "The panel dismissed programmatically and this alert is fully interactive.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Nice", style: .default))
        topVC.present(alert, animated: true)
    }
}
