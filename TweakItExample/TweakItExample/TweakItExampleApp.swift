//
//  TweakItExampleApp.swift
//  TweakItExample
//
//  Created by Ryan McLeod on 3/4/26.
//

import SwiftUI
import TweakIt

@main
struct TweakItExampleApp: App {
    init() {
        let useFloating: Bool = DemoTweaks.store.storage.value(forKey: "App.Panel.useFloatingButton", default: false)
        // Defer to next run loop — UIWindowScene isn't available during App.init()
        DispatchQueue.main.async {
            TweakPanel.install(
                store: DemoTweaks.store,
                tabs: [
                    TweakTab("Plasma", icon: "waveform") { ShaderTabView(categoryName: "Plasma") },
                    TweakTab("Aurora", icon: "sparkles") { ShaderTabView(categoryName: "Aurora") },
                    TweakTab("Marble", icon: "water.waves") { ShaderTabView(categoryName: "Marble") },
                    TweakTab("Voronoi", icon: "hexagon") { ShaderTabView(categoryName: "Voronoi") },
                    TweakTab("Actions", icon: "bolt.fill") { ActionsTabView() },
                ],
                buttonIcon: "gearshape",
                buttonInitiallyVisible: useFloating,
                buttonBottomOffset: 60,
                onDismiss: {
                    print("✅ TweakPanel onDismiss fired")
                }
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
