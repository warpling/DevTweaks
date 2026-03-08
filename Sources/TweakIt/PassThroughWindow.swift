//
//  PassThroughWindow.swift
//  TweakIt
//
//  A UIWindow that passes touches through transparent areas.
//

import UIKit

/// A UIWindow subclass that allows touches to pass through transparent areas.
/// Used for floating buttons and overlay UIs that shouldn't block interaction.
public class PassThroughWindow: UIWindow {

    #if DEBUG
    /// Set by `TweakPanelWindowManager` to the button state that tracks the button's frame.
    @available(iOS 16.0, *)
    weak var buttonState: TweakPanelButtonState? {
        get { _buttonState as? TweakPanelButtonState }
        set { _buttonState = newValue }
    }
    private weak var _buttonState: AnyObject?
    #endif

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        #if DEBUG
        if #available(iOS 16.0, *), let state = buttonState, state.isVisible {
            let screenPoint = convert(point, to: nil)
            return state.buttonFrame.contains(screenPoint)
        }
        #endif
        return false
    }
}
