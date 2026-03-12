//
//  TweakIt.swift
//  TweakIt
//
//  Runtime toggle for enabling/disabling TweakIt.
//

/// Central configuration for TweakIt.
///
/// In DEBUG builds, `isEnabled` defaults to `true`. In all other builds it defaults to `false`.
/// Set `TweakIt.isEnabled = true` before calling `TweakPanel.install()` to enable
/// TweakIt in non-debug configurations (e.g., internal or TestFlight builds).
public enum TweakIt {
    /// Whether TweakIt is active. Defaults to `true` in DEBUG, `false` otherwise.
    /// Set before calling any other TweakIt API.
    public static var isEnabled: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
}
