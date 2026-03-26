//
//  TweakPanelWindowManager.swift
//  TweakIt
//
//  Manages the floating button window and panel presentation window.
//

import UIKit
import SwiftUI

/// Manages the floating button window and the panel presentation window.
///
/// Created and owned by `TweakPanel.install()`. Not a singleton — each install creates one.
@available(iOS 16.0, *)
final class TweakPanelWindowManager: NSObject {
    let store: TweakStore
    let tabs: [TweakTab]
    let onDismiss: (() -> Void)?
    let buttonIcon: String
    let buttonBottomOffset: CGFloat
    let shakeToToggleButton: Bool

    let buttonState: TweakPanelButtonState

    private var buttonWindow: PassThroughWindow?
    private var panelWindow: UIWindow?
    private var sceneObserver: NSObjectProtocol?
    private var activationObserver: NSObjectProtocol?
    private var presentedVCObservation: NSKeyValueObservation?

    init(
        store: TweakStore,
        tabs: [TweakTab],
        buttonIcon: String,
        buttonInitiallyVisible: Bool,
        buttonBottomOffset: CGFloat,
        shakeToToggleButton: Bool,
        onDismiss: (() -> Void)?
    ) {
        self.store = store
        self.tabs = tabs
        self.buttonIcon = buttonIcon
        self.buttonBottomOffset = buttonBottomOffset
        self.shakeToToggleButton = shakeToToggleButton
        self.onDismiss = onDismiss
        self.buttonState = TweakPanelButtonState(initiallyVisible: buttonInitiallyVisible)
        super.init()
    }

    /// Sets up both windows. Safe to call from `didFinishLaunchingWithOptions` —
    /// if no window scene is connected yet, setup defers until one activates.
    func setup() {
        if shakeToToggleButton {
            UIWindow.tweakIt_enableShakeToToggle()
        }

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            // Scene not ready yet — defer until one activates
            sceneObserver = NotificationCenter.default.addObserver(
                forName: UIScene.didActivateNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                if let observer = self?.sceneObserver {
                    NotificationCenter.default.removeObserver(observer)
                    self?.sceneObserver = nil
                }
                self?.setup()
            }
            return
        }

        // Prevent double-setup if called again from the deferred observer
        guard buttonWindow == nil else { return }

        // Button window (always visible, touch-transparent)
        let btnWin = PassThroughWindow(windowScene: scene)
        btnWin.windowLevel = UIWindow.Level.normal + 9
        btnWin.backgroundColor = .clear
        btnWin.buttonState = buttonState

        let container = TweakPanelButtonContainer(state: buttonState, icon: buttonIcon, bottomOffset: buttonBottomOffset) { [weak self] in
            self?.presentPanel()
        }
        let hostingController = UIHostingController(rootView: container)
        hostingController.view.backgroundColor = .clear
        hostingController.view.isOpaque = false
        btnWin.rootViewController = hostingController
        btnWin.isHidden = false
        self.buttonWindow = btnWin

        // Panel window (hidden until presented, passes touches when no sheet is up)
        let pnlWin = PanelWindow(windowScene: scene)
        pnlWin.windowLevel = UIWindow.Level.normal + 10
        pnlWin.backgroundColor = .clear
        pnlWin.isHidden = true
        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        pnlWin.rootViewController = rootVC
        self.panelWindow = pnlWin

        // KVO: hide the panel window whenever `presentedViewController` transitions to nil.
        // This catches ALL dismissal paths: interactive swipe, "Done" button taps, and
        // programmatic dismissal via SwiftUI's @Environment(\.dismiss).
        // `presentationControllerDidDismiss` only fires for interactive dismissals,
        // which is why KVO is needed here.
        presentedVCObservation = rootVC.observe(\.presentedViewController, options: [.old, .new]) { [weak self] _, change in
            // oldValue/newValue are Optional<Optional<UIViewController>> here:
            // the outer optional indicates whether the option was requested,
            // the inner optional is the actual property value.
            let wasPresenting = change.oldValue.flatMap { $0 } != nil
            let isPresenting = change.newValue.flatMap { $0 } != nil
            if wasPresenting && !isPresenting {
                self?.panelWindow?.isHidden = true
                self?.onDismiss?()
            }
        }

        // Safety: hide panelWindow if it ends up visible with no sheet after lifecycle transitions
        activationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, let panelWindow = self.panelWindow, !panelWindow.isHidden else { return }
            if panelWindow.rootViewController?.presentedViewController == nil {
                panelWindow.isHidden = true
            }
        }
    }

    /// Presents the tweak panel as a sheet.
    func presentPanel(selectingTab tabName: String? = nil) {
        guard let panelWindow, let rootVC = panelWindow.rootViewController else { return }
        if rootVC.presentedViewController != nil { return }

        // Write tab selection to UserDefaults BEFORE creating the view,
        // so @AppStorage("TweakIt.lastTab") initializes with the correct value.
        if let tabName {
            var allTabNames = ["Tweaks"]
            allTabNames.append(contentsOf: tabs.map(\.name))
            if let index = allTabNames.firstIndex(of: tabName) {
                UserDefaults.standard.set(index, forKey: "TweakIt.lastTab")
            }
        }

        let panelView = TweakPanelView(store: store, tabs: tabs, onDismiss: onDismiss) { [weak self] in
            self?.panelWindow?.isHidden = true
        }
        let hostingController = UIHostingController(rootView: panelView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
        }

        panelWindow.isHidden = false
        rootVC.present(hostingController, animated: true)
    }
}

// UISheetPresentationControllerDelegate was removed — KVO on presentedViewController
// now handles all dismissal paths (interactive swipe, Done button, programmatic dismiss).

// MARK: - Panel Window

/// A UIWindow that passes all touches through when no view controller is presented.
/// This prevents the panel window from blocking the app when the sheet is dismissed
/// programmatically (e.g., from an action button) — `presentationControllerDidDismiss`
/// only fires for interactive (swipe) dismissals.
private class PanelWindow: UIWindow {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return rootViewController?.presentedViewController != nil
    }
}

// MARK: - Shake Detection

extension UIWindow {
    private static var _tweakItShakeSwizzled = false

    /// Adds a `motionEnded` override on `UIWindow` to detect device shakes.
    /// Idempotent — safe to call multiple times.
    ///
    /// Uses `class_replaceMethod` + `imp_implementationWithBlock` instead of
    /// the traditional selector-swap pattern. This avoids two pitfalls:
    ///   1. `motionEnded` lives on `UIResponder`, not `UIWindow` — a naive
    ///      `method_exchangeImplementations` corrupts every `UIResponder` subclass.
    ///   2. UIResponder's implementation uses `_cmd` to forward up the responder
    ///      chain, so the forwarded selector must stay `motionEnded:with:`.
    static func tweakIt_enableShakeToToggle() {
        guard !_tweakItShakeSwizzled else { return }
        _tweakItShakeSwizzled = true

        let sel = #selector(UIWindow.motionEnded(_:with:))
        guard let method = class_getInstanceMethod(UIWindow.self, sel) else { return }
        let originalIMP = method_getImplementation(method)

        // Cast the original IMP so we can call it with the correct _cmd selector.
        typealias MotionEndedFn = @convention(c) (AnyObject, Selector, UIEvent.EventSubtype, UIEvent?) -> Void
        let originalFn = unsafeBitCast(originalIMP, to: MotionEndedFn.self)

        let block: @convention(block) (AnyObject, UIEvent.EventSubtype, UIEvent?) -> Void = { obj, motion, event in
            // Forward to the original implementation with the correct selector
            // so UIResponder's _cmd-based responder chain forwarding works.
            originalFn(obj, sel, motion, event)

            if motion == .motionShake {
                if #available(iOS 16.0, *) {
                    TweakPanel.buttonState?.toggle()
                }
            }
        }

        // class_replaceMethod adds a UIWindow-scoped override when UIWindow
        // doesn't have its own motionEnded (inherits from UIResponder).
        class_replaceMethod(UIWindow.self, sel, imp_implementationWithBlock(block), method_getTypeEncoding(method))
    }
}
