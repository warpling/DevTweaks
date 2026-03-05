//
//  ContentView.swift
//  TweakItExample
//
//  Created by Ryan McLeod on 3/4/26.
//

import SwiftUI
import TweakIt

struct ContentView: View {
    @State private var selectedTab: AppTab = .shader(.plasma)

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(ShaderType.allCases, id: \.self) { shader in
                Tab(shader.name, systemImage: shader.icon, value: AppTab.shader(shader)) {
                    ShaderView(shaderType: shader)
                        .ignoresSafeArea()
                }
            }

            Tab("Settings", systemImage: "gearshape", value: AppTab.settings, role: .search) {
                Color.clear
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .settings {
                selectedTab = oldValue
                TweakPanel.present()
            }
        }
    }
}

// MARK: - Tab Selection

enum AppTab: Hashable {
    case shader(ShaderType)
    case settings
}
