//
//  ContentView.swift
//  TweakItExample
//
//  Created by Ryan McLeod on 3/4/26.
//

import SwiftUI
import TweakIt

struct ContentView: View {
    @ObservedObject private var storage = DemoTweaks.store.storage
    @State private var selectedTab: AppTab = .shader(.plasma)

    private var useFloatingButton: Bool {
        storage.value(forKey: "App.Panel.useFloatingButton", default: false)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(ShaderType.allCases, id: \.self) { shader in
                Tab(shader.name, systemImage: shader.icon, value: AppTab.shader(shader)) {
                    ShaderView(shaderType: shader)
                        .ignoresSafeArea()
                }
            }

            if !useFloatingButton {
                Tab("Settings", systemImage: "gearshape", value: AppTab.settings, role: .search) {
                    Color.clear
                }
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .settings {
                selectedTab = oldValue
                TweakPanel.present()
            }
        }
        .onChange(of: useFloatingButton) { _, useFloating in
            TweakPanel.buttonState?.isVisible = useFloating
        }
    }
}

// MARK: - Tab Selection

enum AppTab: Hashable {
    case shader(ShaderType)
    case settings
}
