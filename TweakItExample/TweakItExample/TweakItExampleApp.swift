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
        // Defer to next run loop — UIWindowScene isn't available during App.init()
        DispatchQueue.main.async {
            TweakPanel.install(
                store: DemoTweaks.store,
                tabs: [
                    TweakTab("Plasma", icon: "waveform") { ShaderTabView(categoryName: "Plasma") },
                    TweakTab("Aurora", icon: "sparkles") { ShaderTabView(categoryName: "Aurora") },
                    TweakTab("Marble", icon: "water.waves") { ShaderTabView(categoryName: "Marble") },
                    TweakTab("Voronoi", icon: "hexagon") { ShaderTabView(categoryName: "Voronoi") },
                ],
                buttonIcon: "gearshape",
                buttonInitiallyVisible: false // Using the tab bar action button instead
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
