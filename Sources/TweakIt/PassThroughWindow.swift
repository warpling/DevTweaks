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
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        // Pass through if the only hit is the root view itself (no interactive content at this point)
        if result === rootViewController?.view {
            return nil
        }
        return result
    }
}
