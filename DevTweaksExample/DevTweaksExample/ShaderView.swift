//
//  ShaderView.swift
//  DevTweaksExample
//
//  Full-screen shader rendering using TimelineView and .colorEffect().
//

import SwiftUI
import DevTweaks

struct ShaderView: View {
    let shaderType: ShaderType
    @ObservedObject private var storage = DemoTweaks.store.storage

    // Relative time keeps values small enough for float32 precision.
    // timeIntervalSinceReferenceDate (~795M) loses sub-frame deltas.
    private static let startDate = Date()

    var body: some View {
        TimelineView(.animation) { context in
            let time = Float(context.date.timeIntervalSince(Self.startDate))

            Rectangle()
                .fill(.white)
                .visualEffect { content, proxy in
                    let size = proxy.size

                    // Always apply all 3 effects in a fixed chain (required for
                    // consistent opaque return type). Disabled effects use zero
                    // amounts so they act as identity passes.
                    let grainEnabled = boolParam("Post-Processing.Film Grain.enabled")
                    let vignetteEnabled = boolParam("Post-Processing.Vignette.enabled")

                    return content
                        .colorEffect(buildShader(size: size, time: time))
                        .colorEffect(ShaderLibrary.filmGrain(
                            .float2(size),
                            .float(time),
                            .float(grainEnabled ? param("Post-Processing.Film Grain.amount") : 0),
                            .float(grainEnabled ? param("Post-Processing.Film Grain.size") : 1),
                            .float(grainEnabled && boolParam("Post-Processing.Film Grain.animated") ? 1.0 : 0.0)
                        ))
                        .colorEffect(ShaderLibrary.vignette(
                            .float2(size),
                            .float(vignetteEnabled ? param("Post-Processing.Vignette.strength") : 0),
                            .float(vignetteEnabled ? param("Post-Processing.Vignette.radius") : 1)
                        ))
                }
        }
    }

    // MARK: - Shader Selection

    private func buildShader(size: CGSize, time: Float) -> Shader {
        switch shaderType {
        case .plasma:
            ShaderLibrary.plasma(
                .float2(size),
                .float(time * param("Plasma.Motion.speed")),
                .float(param("Plasma.Motion.scale")),
                .float(intParam("Plasma.Color.waveCount")),
                .float(param("Plasma.Color.distortion")),
                .float(param("Plasma.Color.saturation")),
                .float(param("Plasma.Color.brightness")),
                .float(pickerIndex("Plasma.Color.palette", options: ["lava", "ocean", "neon", "pastel", "mono"]))
            )
        case .aurora:
            ShaderLibrary.aurora(
                .float2(size),
                .float(time * param("Aurora.Motion.speed")),
                .float(param("Aurora.Motion.amplitude")),
                .float(intParam("Aurora.Shape.layers")),
                .float(param("Aurora.Shape.verticalCenter")),
                .float(param("Aurora.Shape.bandWidth")),
                .float(param("Aurora.Style.brightness")),
                .float(pickerIndex("Aurora.Style.palette", options: ["arctic", "solar", "cosmic", "fire"])),
                .float(boolParam("Aurora.Style.starField") ? 1.0 : 0.0)
            )
        case .marble:
            ShaderLibrary.marble(
                .float2(size),
                .float(time * param("Marble.Motion.speed")),
                .float(param("Marble.Motion.turbulence")),
                .float(intParam("Marble.Color.octaves")),
                .float(param("Marble.Color.displacement")),
                .float(param("Marble.Color.bandFrequency")),
                .float(param("Marble.Color.colorSeparation")),
                .float(pickerIndex("Marble.Color.palette", options: ["marble", "ink", "oil", "candy"]))
            )
        case .voronoi:
            ShaderLibrary.voronoi(
                .float2(size),
                .float(time),
                .float(param("Voronoi.Cells.cellDensity")),
                .float(param("Voronoi.Cells.morphSpeed")),
                .float(param("Voronoi.Edges.edgeWidth")),
                .float(param("Voronoi.Edges.edgeGlow")),
                .float(fillModeIndex(stringParam("Voronoi.Style.fillMode"))),
                .float(pickerIndex("Voronoi.Style.palette", options: ["crystal", "neon", "earth", "mono"])),
                .float(boolParam("Voronoi.Style.invert") ? 1.0 : 0.0)
            )
        }
    }

    // MARK: - Store Access Helpers

    /// Read a Double tweak and return as Float.
    private func param(_ key: String) -> Float {
        let d: Double = DemoTweaks.store[key]
        return Float(d)
    }

    /// Read an Int tweak (with range -> slider) and return as Float.
    private func intParam(_ key: String) -> Float {
        let i: Int = DemoTweaks.store[key]
        return Float(i)
    }

    /// Read a Bool tweak.
    private func boolParam(_ key: String) -> Bool {
        DemoTweaks.store[key]
    }

    /// Read a String tweak.
    private func stringParam(_ key: String) -> String {
        DemoTweaks.store[key]
    }

    /// Read a String picker tweak and return the index as Float.
    private func pickerIndex(_ key: String, options: [String]) -> Float {
        let name: String = DemoTweaks.store[key]
        return Float(options.firstIndex(of: name) ?? 0)
    }

    private func fillModeIndex(_ name: String) -> Float {
        switch name {
        case "solid": return 0
        case "gradient": return 1
        case "wireframe": return 2
        default: return 1
        }
    }
}
