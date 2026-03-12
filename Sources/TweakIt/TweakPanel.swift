//
//  TweakPanel.swift
//  TweakIt
//
//  Public API for installing and presenting the tweak panel.
//

import UIKit
import SwiftUI

/// Public entry point for installing the TweakIt UI into your app.
///
/// Call `install(store:)` once at launch — it's safe to call from
/// `didFinishLaunchingWithOptions` before a window scene is connected.
///
/// ```swift
/// TweakIt.isEnabled = true  // opt-in for non-debug builds
/// TweakPanel.install(store: AppTweaks.store)
/// ```
public enum TweakPanel {

    @available(iOS 16.0, *)
    private static var windowManager: TweakPanelWindowManager?

    /// Installs the tweak panel UI.
    ///
    /// Safe to call from `didFinishLaunchingWithOptions` — if no window scene
    /// is connected yet, setup defers automatically until one activates.
    /// No-ops when `TweakIt.isEnabled` is `false`.
    ///
    /// - Parameters:
    ///   - store: The `TweakStore` containing all tweak definitions.
    ///   - tabs: Optional custom tabs to show alongside the tweaks browser.
    ///   - buttonIcon: SF Symbol name for the floating button. Defaults to `"slider.vertical.3"`.
    ///   - buttonInitiallyVisible: Whether the floating button starts visible. Defaults to `true`.
    ///   - buttonBottomOffset: Extra bottom padding for the floating button (e.g., to clear a tab bar). Defaults to `0`.
    ///   - shakeToToggleButton: Whether shaking the device toggles button visibility. Defaults to `true`.
    ///   - onDismiss: Optional closure called when the panel is dismissed.
    @available(iOS 16.0, *)
    public static func install(
        store: TweakStore,
        tabs: [TweakTab] = [],
        buttonIcon: String = "slider.vertical.3",
        buttonInitiallyVisible: Bool = true,
        buttonBottomOffset: CGFloat = 0,
        shakeToToggleButton: Bool = true,
        onDismiss: (() -> Void)? = nil
    ) {
        guard TweakIt.isEnabled else { return }

        let manager = TweakPanelWindowManager(
            store: store,
            tabs: tabs,
            buttonIcon: buttonIcon,
            buttonInitiallyVisible: buttonInitiallyVisible,
            buttonBottomOffset: buttonBottomOffset,
            shakeToToggleButton: shakeToToggleButton,
            onDismiss: onDismiss
        )
        manager.setup()
        windowManager = manager
    }

    /// The button state, for toggling visibility from UIKit code.
    @available(iOS 16.0, *)
    public static var buttonState: TweakPanelButtonState? {
        return windowManager?.buttonState
    }

    /// Programmatically presents the tweak panel.
    ///
    /// - Parameter selectingTab: Optional tab name to select on presentation.
    ///   When `nil`, the panel restores the last-used tab.
    @available(iOS 16.0, *)
    public static func present(selectingTab: String? = nil) {
        guard TweakIt.isEnabled else { return }
        windowManager?.presentPanel(selectingTab: selectingTab)
    }

    /// Creates a `UIWindow` subclass with a two-finger double-tap gesture that opens the panel.
    ///
    /// Use this as your app's main window if you want the gesture shortcut:
    /// ```swift
    /// window = TweakPanel.makeWindow(windowScene: windowScene)
    /// ```
    @available(iOS 16.0, *)
    public static func makeWindow(frame: CGRect) -> UIWindow {
        guard TweakIt.isEnabled else { return UIWindow(frame: frame) }
        return TweakGestureWindow(frame: frame)
    }

    /// Creates a `UIWindow` subclass with a two-finger double-tap gesture that opens the panel.
    @available(iOS 16.0, *)
    public static func makeWindow(windowScene: UIWindowScene) -> UIWindow {
        guard TweakIt.isEnabled else { return UIWindow(windowScene: windowScene) }
        return TweakGestureWindow(windowScene: windowScene)
    }
}

// MARK: - Gesture Window

/// A UIWindow that captures two-finger double-tap to present the tweak panel.
@available(iOS 16.0, *)
final class TweakGestureWindow: UIWindow {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGesture()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGesture()
    }

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        setupGesture()
    }

    private func setupGesture() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.numberOfTapsRequired = 2
        gesture.numberOfTouchesRequired = 2
        gesture.cancelsTouchesInView = false
        gesture.delaysTouchesBegan = false
        gesture.delaysTouchesEnded = false
        addGestureRecognizer(gesture)
    }

    @objc private func handleGesture(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .recognized else { return }
        TweakPanel.present()
    }
}
