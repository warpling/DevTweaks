# TweakIt

A Swift debug-panel library for runtime parameter tweaking. iOS 16+, SwiftUI, zero dependencies.

## Project Rules

### Build Verification
- This is a **public library** consumed via SPM. Breaking changes affect all downstream apps.
- Always consider **both Debug and Release** build configurations. Code guarded by `#if DEBUG` does not exist in Release builds — any type, property, or method defined inside `#if DEBUG` must only be referenced from other `#if DEBUG` blocks.
- UIKit is only available when targeting iOS. `swift build` on macOS will fail on UIKit imports — this is expected and not a real error.

### Objective-C Runtime / Swizzling
- **Never use `method_exchangeImplementations` on inherited methods.** Most UIKit classes (UIWindow, UIViewController, etc.) inherit methods from superclasses like UIResponder. Swizzling an inherited method corrupts the superclass and crashes unrelated subclasses.
- **Always use `imp_implementationWithBlock` + `class_replaceMethod`** instead of selector-swap patterns. This avoids both the inheritance scoping problem and the `_cmd` forwarding problem (UIKit internally uses `_cmd` to forward events up the responder chain).
- Before writing any swizzling code, consider: what class actually owns this method? Will `_cmd` be used downstream? Can we avoid swizzling entirely?

### Code Quality
- Think through changes from the perspective of a downstream app integrating this library. Consider SwiftUI hosting controllers, presentation controllers, and other internal UIKit subclasses that may interact with swizzled methods.
- Prefer simple, non-invasive approaches (subclass overrides, notification observers) over runtime tricks (swizzling, associated objects) whenever possible.
