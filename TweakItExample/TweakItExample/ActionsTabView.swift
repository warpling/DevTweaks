//
//  ActionsTabView.swift
//  TweakItExample
//
//  Custom tab demonstrating programmatic panel dismissal.
//  Tests that the onDismiss callback fires and the panel window
//  hides after a programmatic dismiss (not just interactive swipe).
//

import SwiftUI
import TweakIt

struct ActionsTabView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Button {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        presentAlert()
                    }
                } label: {
                    Label("Dismiss & Present Alert", systemImage: "exclamationmark.bubble")
                }
            } header: {
                Text("Programmatic Dismiss")
            } footer: {
                Text("Dismisses the panel via SwiftUI's dismiss(), then presents an alert. The alert title shows whether onDismiss fired. If the alert is not tappable, the panel window is still blocking touches.")
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
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }

        // Find the app's own window — skip TweakIt's overlay windows (level > .normal).
        guard let rootVC = scene.windows
            .first(where: { $0.windowLevel == .normal })?.rootViewController else {
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        // Check if onDismiss fired by looking at whether the panel window is hidden.
        // If KVO fix works: window is hidden, onDismiss fired → "onDismiss: YES"
        // If broken: window is still visible → "onDismiss: NO" (and this alert won't be tappable)
        let panelWindowHidden = scene.windows
            .first(where: { $0.windowLevel == UIWindow.Level.normal + 10 })?
            .isHidden ?? true

        let alert = UIAlertController(
            title: panelWindowHidden ? "onDismiss: YES" : "onDismiss: NO",
            message: panelWindowHidden
                ? "Panel window hidden. Touches work. Everything is correct."
                : "Panel window still visible. If you can read this, point(inside:) is passing touches but onDismiss did not fire.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        topVC.present(alert, animated: true)
    }
}
