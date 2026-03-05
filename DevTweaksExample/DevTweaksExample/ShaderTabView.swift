//
//  ShaderTabView.swift
//  DevTweaksDemo
//
//  Reusable tab view that lists sections for a shader category
//  with NavigationLinks to TweakSectionDetailView.
//

import SwiftUI
import DevTweaks

struct ShaderTabView: View {
    let categoryName: String
    @ObservedObject private var storage = DemoTweaks.store.storage

    private var category: TweakCategoryMetadata? {
        DemoTweaks.store.categories.first { $0.name == categoryName }
    }

    var body: some View {
        Group {
            if let category {
                List {
                    ForEach(category.sections) { section in
                        NavigationLink {
                            TweakSectionDetailView(section: section, storage: storage)
                        } label: {
                            HStack {
                                Text(section.name)
                                Spacer()
                                let count = storage.modifiedCount(forSection: section.id)
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.orange.opacity(0.15), in: Capsule())
                                }
                            }
                        }
                    }
                }
            } else {
                Text("Category \"\(categoryName)\" not found")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
