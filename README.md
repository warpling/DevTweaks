# DevTweaks

Runtime-adjustable debug parameters for iOS apps. Define tweaks once in a declarative DSL, get a full debug UI for free.

**iOS 16+ | Swift 5.9+ | Zero dependencies | SwiftUI panel | DEBUG-only overhead**

<!-- ![DevTweaks panel screenshot](screenshot.png) -->

## Installation

Add via Swift Package Manager:

```
https://github.com/warpling/DevTweaks.git
```

Or in `Package.swift`:

```swift
.package(url: "https://github.com/warpling/DevTweaks.git", from: "0.1.0")
```

## Quick Start

### 1. Define your tweaks

```swift
import DevTweaks

enum AppTweaks {
    static let store = TweakStore {
        TweakCategory("Visual", icon: "eye") {
            TweakSection("Animations") {
                TweakDefinition("duration", default: 0.46, range: 0.1...2.0)
                TweakDefinition("damping", default: 0.8, range: 0.1...1.0)
                TweakDefinition("glassButtons", default: true)
            }
        }
        TweakCategory("Debug", icon: "ladybug") {
            TweakSection("Network") {
                TweakDefinition("mockMode", default: false)
                TweakDefinition("endpoint", default: "production", options: ["production", "staging", "local"])
            }
        }
    }
}
```

### 2. Install the panel

```swift
// AppDelegate or SceneDelegate
#if DEBUG
TweakPanel.install(store: AppTweaks.store)
#endif
```

This adds:
- A floating button (bottom-left) that opens the panel
- A two-finger double-tap gesture on the main window

### 3. Read values

```swift
let duration: CGFloat = AppTweaks.store["Visual.Animations.duration"]
```

## DSL Reference

### Control types

The control type is inferred from the default value and parameters:

| Definition | Control | Preview |
|---|---|---|
| `TweakDefinition("flag", default: true)` | Toggle | On/Off switch |
| `TweakDefinition("speed", default: 0.5, range: 0.0...1.0)` | Slider | Continuous slider |
| `TweakDefinition("speed", default: CGFloat(0.5), range: 0.0...1.0)` | Slider | CGFloat slider |
| `TweakDefinition("columns", default: 3)` | Stepper | +/- stepper |
| `TweakDefinition("columns", default: 3, range: 0.0...10.0)` | Slider | Int slider |
| `TweakDefinition("name", default: "hello")` | Text field | Editable text |
| `TweakDefinition("env", default: "prod", options: ["prod", "staging"])` | Picker | Segmented picker |
| `TweakDefinition("reset", action: { ... })` | Button | Tap to fire |

### Sections with master toggle

```swift
TweakSection("Feature Flags", hasMasterToggle: true) {
    TweakDefinition("newUI", default: false)
    TweakDefinition("darkMode", default: true)
}
```

The master toggle enables/disables the entire section. Check it with:

```swift
store.isSectionEnabled("Debug.Feature Flags")
```

### Section metadata

Sections support optional `tag` and `color` for app-specific decoration:

```swift
TweakSection("Rotation", hasMasterToggle: true, tag: MyType.rotation, color: .blue) {
    TweakDefinition("easier", default: false)
}
```

## TweakRef Pattern

For ergonomic access, use `TweakRef` to create typed handles:

```swift
enum AppTweaks {
    static let store = TweakStore { ... }

    // Type-inferred (recommended when type annotation is present):
    static let duration: TweakRef<CGFloat> = store.ref("Visual.Animations.duration")

    // Explicit type parameter (works everywhere):
    static let damping = store.ref("Visual.Animations.damping", as: CGFloat.self)
}

// Usage:
let d = AppTweaks.duration.value
AppTweaks.duration.value = 0.5
AppTweaks.duration.isModified  // true
AppTweaks.duration.reset()     // back to 0.46
```

In release builds, `.value` returns the compile-time default directly with zero overhead.

## Custom Tabs

Add app-specific panels alongside the built-in tweaks browser:

```swift
TweakPanel.install(
    store: AppTweaks.store,
    tabs: [
        TweakTab("Actions", icon: "bolt") { ActionsView() },
        TweakTab("Stats", icon: "chart.bar") { StatsView() },
    ]
)
```

## Programmatic Presentation

```swift
// Open to last-used tab:
TweakPanel.present()

// Open to a specific tab:
TweakPanel.present(selectingTab: "Actions")
```

## Floating Button

Control the floating button visibility:

```swift
TweakPanel.buttonState?.toggle()
TweakPanel.buttonState?.isVisible = false
```

Or start hidden:

```swift
TweakPanel.install(store: store, buttonInitiallyVisible: false)
```

## Gesture Window

Use `TweakPanel.makeWindow(windowScene:)` as your app's main window to get the two-finger double-tap gesture automatically:

```swift
window = TweakPanel.makeWindow(windowScene: windowScene)
```

## Release Build Safety

All UI code is wrapped in `#if DEBUG`. In release builds:

- `TweakPanel.install()` / `present()` are no-ops
- `TweakRef.value` returns the compile-time default (inlineable)
- `TweakRef.isModified` returns `false`
- No windows, gestures, or buttons are created

The `TweakStore` DSL and `TweakStorage` are available in all builds so you can define stores unconditionally. Only the UI presentation layer is DEBUG-gated.

## License

MIT License. See [LICENSE](LICENSE) for details.
