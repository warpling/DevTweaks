//
//  TweakPanelButton.swift
//  TweakIt
//
//  Floating button that opens the tweak panel. Supports liquid glass on iOS 26+.
//

#if DEBUG
import SwiftUI

/// Observable state for the floating button visibility, controllable from UIKit.
@available(iOS 16.0, *)
public final class TweakPanelButtonState: ObservableObject {
    @Published public var isVisible: Bool

    /// Button frame in screen coordinates, updated by SwiftUI geometry.
    /// Read by PassThroughWindow for hit testing — not @Published to avoid re-renders.
    var buttonFrame: CGRect = .zero

    public init(initiallyVisible: Bool = true) {
        self.isVisible = initiallyVisible
    }

    public func toggle() {
        withAnimation(.bouncy) {
            isVisible.toggle()
        }
    }
}

// MARK: - Button Frame Preference Key

@available(iOS 16.0, *)
private struct ButtonFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

/// Container view that hosts the floating button with glass transitions on iOS 26+.
@available(iOS 16.0, *)
struct TweakPanelButtonContainer: View {
    @ObservedObject var state: TweakPanelButtonState
    let icon: String
    let bottomOffset: CGFloat
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                if state.isVisible {
                    TweakPanelFloatingButton(icon: icon, action: action)
                        .glassEffectID("tweakItButton", in: glassNamespace)
                        .reportButtonFrame()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(16)
            .padding(.bottom, bottomOffset)
            .onPreferenceChange(ButtonFrameKey.self) { state.buttonFrame = $0 }
        } else {
            Group {
                if state.isVisible {
                    TweakPanelFloatingButton(icon: icon, action: action)
                        .transition(.scale.combined(with: .opacity))
                        .reportButtonFrame()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(16)
            .padding(.bottom, bottomOffset)
            .onPreferenceChange(ButtonFrameKey.self) { state.buttonFrame = $0 }
        }
    }

    @Namespace private var glassNamespace
}

@available(iOS 16.0, *)
private extension View {
    func reportButtonFrame() -> some View {
        background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ButtonFrameKey.self, value: geo.frame(in: .global))
            }
        )
    }
}

/// The floating button itself.
@available(iOS 16.0, *)
struct TweakPanelFloatingButton: View {
    let icon: String
    let action: () -> Void

    private let buttonSize: CGFloat = 62
    private let iconSize: CGFloat = 20

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(.plain)
            .clipShape(Circle())
            .glassEffect(.regular.interactive())
            .environment(\.colorScheme, .dark)
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            .accessibilityLabel("Dev Tools")
            .accessibilityHint("Opens developer tools panel")
        } else {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: buttonSize, height: buttonSize)
                    .background {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                    }
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(FloatingButtonStyle())
            .accessibilityLabel("Dev Tools")
            .accessibilityHint("Opens developer tools panel")
        }
    }
}
#endif
