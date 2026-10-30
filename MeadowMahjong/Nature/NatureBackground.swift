import SwiftUI

/// The animated landscape behind every screen: sky, sun or moon, drifting
/// clouds, three parallax hills with trees, swaying grass and flowers, falling
/// petals or leaves, butterflies, birds and fireflies.
///
/// Everything is drawn in one `Canvas` from the time alone, with no stored
/// state, so it costs one draw pass per frame and never needs resetting.
struct NatureBackground: View {
    let scenery: Scenery
    var animated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !animated || reduceMotion)) { context in
            let t = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 86_400)
            Canvas { ctx, size in
                ScenePainter(palette: scenery.palette, t: t, size: size).paint(&ctx)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ScenePainter {
    let palette: ScenePalette
    let t: Double
    let size: CGSize

    private var w: Double { Double(size.width) }
    private var h: Double { Double(size.height) }

    func paint(_ ctx: inout GraphicsContext) {
        sky(&ctx)
        if palette.stars { stars(&ctx) }
        sun(&ctx)
        if palette.beams { beams(&ctx) }
        clouds(&ctx)
        for layer in 0..<3 {
            hill(&ctx, layer: layer)
            if layer == 1, let trees = palette.trees { self.trees(&ctx, style: trees) }
            if layer == 1, palette.mist { mist(&ctx) }
        }
        if palette.water { water(&ctx) }
        if !palette.water { grass(&ctx) }   // no grass growing out of the lake
        if !palette.flowers.isEmpty { flowers(&ctx) }
        if palette.birds > 0 { birds(&ctx) }
        if palette.butterflies > 0 { butterflies(&ctx) }
        if palette.particleCount > 0 { fallingParticles(&ctx) }
        if palette.fireflies > 0 { fireflies(&ctx) }
    }

    // MARK: - Sky

    private func sky(_ ctx: inout GraphicsContext) {
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: palette.sky.map { Color(hex: $0) }),
                                       startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.75)))
    }

    private func stars(_ ctx: inout GraphicsContext) {
        for i in 0..<70 {
            let p = CGPoint(x: noise(i, 1) * w, y: noise(i, 2) * h * 0.55)
            let twinkle = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * (0.8 + noise(i, 3) * 2.2) + Double(i)))
            let r = 0.6 + noise(i, 4) * 1.4
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)),
                     with: .color(.white.opacity(twinkle)))
        }
    }

    private func sun(_ ctx: inout GraphicsContext) {
        let c = CGPoint(x: Double(palette.sunAt.x) * w, y: Double(palette.sunAt.y) * h)
        let r = min(w, h) * 0.07 * Double(palette.sunScale)
        let pulse = 1 + 0.06 * sin(t * 0.9)
        let color = Color(hex: palette.sun)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 4, y: c.y - r * 4, width: r * 8, height: r * 8)),
                 with: .radialGradient(Gradient(colors: [color.opacity(0.55), color.opacity(0)]),
                                       center: c, startRadius: r * 0.8, endRadius: r * 4 * pulse))
        if !palette.isNight {
            var rays = ctx
            rays.translateBy(x: c.x, y: c.y)
            rays.rotate(by: .radians(t * 0.05))
            for k in 0..<12 {
                var ray = Path()
                let a = Double(k) / 12 * 2 * .pi
                let spread = 0.07
                ray.move(to: .zero)
                ray.addLine(to: CGPoint(x: cos(a - spread) * r * 3.4, y: sin(a - spread) * r * 3.4))
                ray.addLine(to: CGPoint(x: cos(a + spread) * r * 3.4, y: sin(a + spread) * r * 3.4))
                ray.closeSubpath()
                rays.fill(ray, with: .color(color.opacity(0.16)))
            }
        }
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(color))
        if palette.isNight {
            // Crescent: cut the moon with a sky-coloured circle.
            let skyTop = Color(hex: palette.sky[0])
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.55, y: c.y - r * 1.15, width: r * 2, height: r * 2)),
                     with: .color(skyTop.opacity(0.92)))
        }
    }

    private func beams(_ ctx: inout GraphicsContext) {
        var layer = ctx
        layer.blendMode = .plusLighter
        for k in 0..<4 {
            let x0 = w * (0.05 + 0.22 * Double(k)) + sin(t * 0.2 + Double(k)) * 12
            let opacity = 0.07 + 0.05 * (0.5 + 0.5 * sin(t * 0.4 + Double(k) * 1.7))
            var beam = Path()
            beam.move(to: CGPoint(x: x0, y: -10))
            beam.addLine(to: CGPoint(x: x0 + 40, y: -10))
            beam.addLine(to: CGPoint(x: x0 + 40 + h * 0.35, y: h * 0.75))
            beam.addLine(to: CGPoint(x: x0 + h * 0.35 - 30, y: h * 0.75))
            beam.closeSubpath()
            layer.fill(beam, with: .color(.white.opacity(opacity)))
        }
    }

    private func clouds(_ ctx: inout GraphicsContext) {
        let color = Color(hex: palette.cloud)
        for i in 0..<5 {
            let speed = 6 + noise(i, 11) * 10
            let span = w + 260
            let x = (noise(i, 12) * span + t * speed).truncatingRemainder(dividingBy: span) - 130
            let y = h * (0.06 + noise(i, 13) * 0.3)
            let s = 0.6 + noise(i, 14) * 0.7
            let opacity = palette.isNight ? 0.35 : 0.85
            for (dx, dy, rw, rh) in [(-40.0, 6.0, 60.0, 30.0), (-8, -10, 64, 42), (28, 2, 58, 32), (0, 10, 110, 26)] {
                let rect = CGRect(x: x + dx * s - rw * s / 2, y: y + dy * s - rh * s / 2, width: rw * s, height: rh * s)
                ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(opacity)))
            }
        }
    }

    // MARK: - Land

    /// Hills scroll slowly sideways, the front ones faster, so the scene drifts like a train window.
    private func scroll(_ layer: Int) -> Double { t * [3.0, 6.0, 10.0][layer] }

    private func hillY(_ x: Double, layer: Int) -> Double {
        let base = [0.6, 0.7, 0.82][layer] * h
        let amp = [0.07, 0.05, 0.035][layer] * h
        let wx = (x + scroll(layer)) / max(w, 1)
        let k1 = [1.1, 1.7, 2.3][layer] * 2 * .pi
        let k2 = [2.9, 3.7, 4.9][layer] * 2 * .pi
        return base - amp * (0.65 * sin(wx * k1 + Double(layer)) + 0.35 * sin(wx * k2 + Double(layer) * 2.1))
    }

    private func hill(_ ctx: inout GraphicsContext, layer: Int) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))
        stride(from: 0.0, through: w + 8, by: 8).forEach { path.addLine(to: CGPoint(x: $0, y: hillY($0, layer: layer))) }
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        let color = Color(hex: palette.hills[layer])
        ctx.fill(path, with: .linearGradient(Gradient(colors: [color, color.opacity(0.9)]),
                                             startPoint: CGPoint(x: 0, y: h * 0.5), endPoint: CGPoint(x: 0, y: h)))
    }

    private func trees(_ ctx: inout GraphicsContext, style: ScenePalette.Trees) {
        let spacing: Double = 46
        let offset = scroll(1)
        let first = Int(floor(offset / spacing)) - 1
        for j in first...(first + Int(w / spacing) + 2) {
            guard noise(j, 21) > 0.35 else { continue }
            let x = Double(j) * spacing - offset + noise(j, 22) * 20
            let ground = hillY(x, layer: 1) + 4
            let height = 34 + noise(j, 23) * 34
            let sway = sin(t * 1.2 + Double(j)) * 2
            switch style {
            case .pine(let hex):
                let color = Color(hex: hex)
                for tier in 0..<3 {
                    let tw = height * (0.55 - Double(tier) * 0.12)
                    let ty = ground - height * Double(tier) * 0.28
                    var p = Path()
                    p.move(to: CGPoint(x: x - tw / 2, y: ty))
                    p.addLine(to: CGPoint(x: x + tw / 2, y: ty))
                    p.addLine(to: CGPoint(x: x + sway, y: ty - height * 0.5))
                    p.closeSubpath()
                    ctx.fill(p, with: .color(color))
                }
            case .round(let hex):
                ctx.fill(Path(CGRect(x: x - 2.5, y: ground - height * 0.5, width: 5, height: height * 0.5)),
                         with: .color(Color(hex: 0x6B4A2E)))
                let r = height * 0.32
                let canopy = Color(hex: hex)
                for (dx, dy, k) in [(-0.5, 0.1, 0.8), (0.5, 0.1, 0.8), (0.0, -0.35, 1.0)] {
                    let cx = x + dx * r + sway, cy = ground - height * 0.62 + dy * r
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - r * k, y: cy - r * k, width: r * 2 * k, height: r * 2 * k)),
                             with: .color(canopy))
                }
                ctx.fill(Path(ellipseIn: CGRect(x: x - r * 0.5 + sway, y: ground - height * 0.86, width: r * 0.7, height: r * 0.5)),
                         with: .color(.white.opacity(0.18)))
            }
        }
    }

    private func mist(_ ctx: inout GraphicsContext) {
        for k in 0..<3 {
            let y = h * (0.62 + 0.06 * Double(k))
            let x = sin(t * 0.08 + Double(k) * 2) * w * 0.2
            ctx.fill(Path(ellipseIn: CGRect(x: x - w * 0.3, y: y - 24, width: w * 1.6, height: 48)),
                     with: .color(.white.opacity(0.18)))
        }
    }

    private func water(_ ctx: inout GraphicsContext) {
        let top = h * 0.74
        let rect = CGRect(x: 0, y: top, width: w, height: h - top)
        ctx.fill(Path(rect), with: .linearGradient(
            Gradient(colors: [Color(hex: palette.sky[2]).opacity(0.9), Color(hex: palette.sky[0])]),
            startPoint: CGPoint(x: 0, y: top), endPoint: CGPoint(x: 0, y: h)))
        let sunX = Double(palette.sunAt.x) * w
        for i in 0..<26 {
            let row = Double(i % 13)
            let y = top + 8 + row * (h - top) / 14
            let spread = 20 + row * 9
            let x = sunX + (noise(i, 31) - 0.5) * spread * 2 + sin(t * (0.7 + noise(i, 32)) + Double(i)) * 10
            let len = 14 + noise(i, 33) * 30
            let opacity = 0.25 + 0.45 * (0.5 + 0.5 * sin(t * 1.3 + Double(i) * 0.9))
            ctx.fill(Path(roundedRect: CGRect(x: x - len / 2, y: y, width: len, height: 2.5), cornerRadius: 1.25),
                     with: .color(Color(hex: palette.sun).opacity(opacity)))
        }
    }

    private func grass(_ ctx: inout GraphicsContext) {
        let spacing: Double = 7
        let offset = scroll(2)
        let first = Int(floor(offset / spacing)) - 1
        let color = Color(hex: palette.grass)
        var blades = Path()
        for j in first...(first + Int(w / spacing) + 2) {
            let x = Double(j) * spacing - offset
            let ground = hillY(x, layer: 2) + 6
            let height = 10 + noise(j, 41) * 18
            let sway = sin(t * 1.8 + Double(x) * 0.025) * (4 + height * 0.2)
            blades.move(to: CGPoint(x: x - 1.6, y: ground))
            blades.addQuadCurve(to: CGPoint(x: x + sway, y: ground - height), control: CGPoint(x: x, y: ground - height * 0.6))
            blades.addQuadCurve(to: CGPoint(x: x + 1.6, y: ground), control: CGPoint(x: x + 0.6, y: ground - height * 0.5))
        }
        ctx.fill(blades, with: .color(color.opacity(0.85)))
    }

    private func flowers(_ ctx: inout GraphicsContext) {
        let spacing: Double = 38
        let offset = scroll(2)
        let first = Int(floor(offset / spacing)) - 1
        for j in first...(first + Int(w / spacing) + 2) {
            guard noise(j, 51) > 0.3 else { continue }
            let x = Double(j) * spacing - offset + noise(j, 52) * 16
            let ground = hillY(x, layer: 2) + 14 + noise(j, 53) * 30
            let bob = sin(t * 2 + Double(j)) * 2
            let color = Color(hex: palette.flowers[abs(j) % palette.flowers.count])
            let r = 3.2 + noise(j, 54) * 1.6
            ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: ground + 10)); p.addLine(to: CGPoint(x: x + bob, y: ground)) },
                       with: .color(Color(hex: palette.grass)), lineWidth: 1.5)
            for k in 0..<5 {
                let a = Double(k) / 5 * 2 * .pi + t * 0.3
                let px = x + bob + cos(a) * r, py = ground + sin(a) * r
                ctx.fill(Path(ellipseIn: CGRect(x: px - r * 0.75, y: py - r * 0.75, width: r * 1.5, height: r * 1.5)), with: .color(color))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: x + bob - r * 0.55, y: ground - r * 0.55, width: r * 1.1, height: r * 1.1)),
                     with: .color(Color(hex: 0xFFC83D)))
        }
    }

    // MARK: - Life

    private func fallingParticles(_ ctx: inout GraphicsContext) {
        for i in 0..<palette.particleCount {
            let speed = 22 + noise(i, 61) * 34
            let span = h + 80
            let y = (noise(i, 62) * span + t * speed).truncatingRemainder(dividingBy: span) - 40
            let x = noise(i, 63) * w + sin(t * (0.5 + noise(i, 64)) + Double(i)) * 34 + (y / h) * 30
            let spin = t * (0.8 + noise(i, 65) * 1.6) + Double(i)
            let color = Color(hex: palette.particles[i % palette.particles.count])
            var p = ctx
            p.translateBy(x: x, y: y)
            p.rotate(by: .radians(spin))
            p.scaleBy(x: cos(spin * 1.3), y: 1)     // flutter: turns edge-on and back
            let s = 0.8 + noise(i, 66) * 0.6
            switch palette.particle {
            case .petal:
                p.fill(Path(ellipseIn: CGRect(x: -6 * s, y: -3.5 * s, width: 12 * s, height: 7 * s)), with: .color(color.opacity(0.95)))
            case .leaf:
                var leaf = Path()
                leaf.move(to: CGPoint(x: -8 * s, y: 0))
                leaf.addQuadCurve(to: CGPoint(x: 8 * s, y: 0), control: CGPoint(x: 0, y: -7 * s))
                leaf.addQuadCurve(to: CGPoint(x: -8 * s, y: 0), control: CGPoint(x: 0, y: 7 * s))
                p.fill(leaf, with: .color(color))
                p.stroke(Path { $0.move(to: CGPoint(x: -8 * s, y: 0)); $0.addLine(to: CGPoint(x: 8 * s, y: 0)) },
                         with: .color(.black.opacity(0.15)), lineWidth: 0.8)
            case .sparkle:
                let r = 2.5 * s
                p.fill(Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)), with: .color(color.opacity(0.8)))
            }
        }
    }

    private func butterflies(_ ctx: inout GraphicsContext) {
        let colors: [UInt32] = [0xFFB347, 0x7FD1FF, 0xFF8FC7, 0xFFF06B]
        for i in 0..<palette.butterflies {
            let fi = Double(i)
            let x = w * (0.5 + 0.42 * sin(t * 0.11 * (1 + fi * 0.37) + fi * 2.1))
            let y = h * (0.5 + 0.2 * sin(t * 0.19 + fi * 1.3)) + sin(t * 3 + fi) * 6
            let heading = cos(t * 0.11 * (1 + fi * 0.37) + fi * 2.1)   // derivative of x: which way it flies
            let flap = 0.25 + 0.75 * abs(sin(t * 10 + fi))
            let color = Color(hex: colors[i % colors.count])
            var b = ctx
            b.translateBy(x: x, y: y)
            b.scaleBy(x: heading >= 0 ? 1 : -1, y: 1)
            b.rotate(by: .degrees(-12))
            for side in [-1.0, 1.0] {
                var wing = b
                wing.scaleBy(x: side * flap, y: 1)
                wing.fill(Path(ellipseIn: CGRect(x: 0, y: -11, width: 11, height: 12)), with: .color(color))
                wing.fill(Path(ellipseIn: CGRect(x: 0, y: -1, width: 8, height: 9)), with: .color(color.opacity(0.85)))
                wing.fill(Path(ellipseIn: CGRect(x: 4, y: -7, width: 3.5, height: 3.5)), with: .color(.white.opacity(0.7)))
            }
            b.fill(Path(roundedRect: CGRect(x: -1.2, y: -9, width: 2.4, height: 16), cornerRadius: 1.2), with: .color(Color(hex: 0x3A2A1A)))
        }
    }

    private func birds(_ ctx: inout GraphicsContext) {
        for i in 0..<palette.birds {
            let fi = Double(i)
            let speed = 18 + noise(i, 71) * 14
            let span = w + 120
            let x = (noise(i, 72) * span + t * speed).truncatingRemainder(dividingBy: span) - 60
            let y = h * (0.12 + noise(i, 73) * 0.22) + sin(t * 0.7 + fi) * 8
            let flap = sin(t * 7 + fi * 1.9)
            let s = 5 + noise(i, 74) * 3
            var p = Path()
            p.move(to: CGPoint(x: x - s, y: y - s * 0.5 * flap))
            p.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - s * 0.5, y: y - s * 0.6))
            p.addQuadCurve(to: CGPoint(x: x + s, y: y - s * 0.5 * flap), control: CGPoint(x: x + s * 0.5, y: y - s * 0.6))
            ctx.stroke(p, with: .color(Color(hex: palette.isNight ? 0xC9D2FF : 0x3D3A4F).opacity(0.75)), lineWidth: 1.6)
        }
    }

    private func fireflies(_ ctx: inout GraphicsContext) {
        var glow = ctx
        glow.blendMode = .plusLighter
        for i in 0..<palette.fireflies {
            let fi = Double(i)
            let x = w * (noise(i, 81) + 0.06 * sin(t * 0.3 * (1 + noise(i, 82)) + fi))
            let y = h * (0.42 + 0.5 * noise(i, 83)) + 18 * sin(t * 0.5 + fi * 1.7)
            let blink = max(0, sin(t * (0.9 + noise(i, 84)) + fi * 2))
            let alpha = blink * blink
            let r = 10.0
            let color = Color(hex: 0xFFF59D)
            glow.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                      with: .radialGradient(Gradient(colors: [color.opacity(0.9 * alpha), color.opacity(0)]),
                                            center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r))
            glow.fill(Path(ellipseIn: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)), with: .color(.white.opacity(alpha)))
        }
    }

    /// A fixed pseudo-random number in 0..<1 for (index, salt), so every frame agrees.
    private func noise(_ i: Int, _ salt: Int) -> Double {
        var x = UInt64(bitPattern: Int64(i &* 73_856_093)) ^ UInt64(salt &* 19_349_663) &+ 0x9E37_79B9_7F4A_7C15
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9
        x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        x ^= x >> 31
        return Double(x % 10_000) / 10_000
    }
}
