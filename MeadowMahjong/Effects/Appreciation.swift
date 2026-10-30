import SwiftUI

/// Sparkles, leaves and a ring flying out from a match. Bigger for bigger combos.
struct SparkleBurst: View {
    var intensity = 1

    @State private var go = false

    private var count: Int { min(8 + intensity * 2, 20) }
    private var reach: CGFloat { 50 + CGFloat(min(intensity, 6)) * 10 }
    private static let colors: [Color] = [Theme.sunshine, .white, Theme.blossom, Color(hex: 0x9BE15D)]
    private static let symbols = ["sparkle", "leaf.fill", "star.fill", "camera.macro"]

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Theme.sunshine.opacity(0.9), lineWidth: go ? 1 : 7)
                .frame(width: go ? reach * 2 : 14, height: go ? reach * 2 : 14)
                .opacity(go ? 0 : 1)
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 2 * .pi + Double(i % 3) * 0.2
                let distance = reach * (0.7 + 0.3 * CGFloat(i % 3) / 2)
                Image(systemName: Self.symbols[i % Self.symbols.count])
                    .font(.system(size: 13 + CGFloat(i % 3) * 4, weight: .bold))
                    .foregroundStyle(Self.colors[i % Self.colors.count])
                    .shadow(color: .black.opacity(0.15), radius: 1)
                    .rotationEffect(.degrees(go ? 180 : 0))
                    .scaleEffect(go ? 0.4 : 1.1)
                    .offset(x: go ? CGFloat(cos(angle)) * distance : 0, y: go ? CGFloat(sin(angle)) * distance : 0)
                    .opacity(go ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.65)) { go = true }
        }
    }
}

/// The big praise word: pops in on a spring with gradient lettering, an outline,
/// sun rays from "Excellent!" up and a petal shower from "Amazing!" up.
struct PraiseView: View {
    let praise: GameModel.Praise

    @State private var shown = false
    @State private var spin = false

    private var style: (fill: [Color], outline: Color) {
        switch praise.tier {
        case ...1: ([.white, Color(hex: 0xC9F7D4)], Color(hex: 0x1F5D3A))
        case 2: ([Color(hex: 0xD8FF9E), Color(hex: 0x4CB944)], Color(hex: 0x1D5A27))
        case 3: ([Color(hex: 0xC4F1FF), Color(hex: 0x2E8BD8)], Color(hex: 0x173F73))
        case 4: ([Color(hex: 0xFFF1A1), Color(hex: 0xF29A1D)], Color(hex: 0x7A3E00))
        case 5: ([Color(hex: 0xFFD6EC), Color(hex: 0xE8458B)], Color(hex: 0x6E1240))
        case 6: ([Color(hex: 0xEBD7FF), Color(hex: 0x8A4FE0)], Color(hex: 0x3A1873))
        default: ([Color(hex: 0xFFE66D), Color(hex: 0xFF6B9A), Color(hex: 0x7B6CFF)], Color(hex: 0x3A1450))
        }
    }

    var body: some View {
        let size = 40 + CGFloat(min(praise.tier, 7)) * 3
        ZStack {
            if praise.tier >= 4 {
                SunRays(color: style.fill.first ?? .white)
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(spin ? 40 : 0))
                    .opacity(shown ? 0.55 : 0)
            }
            VStack(spacing: 2) {
                outlined(Text(praise.text).font(Theme.display(size)))
                if praise.tier >= 2 {
                    Text("Combo ×\(praise.tier)")
                        .font(Theme.body(17))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(style.outline.opacity(0.85)))
                }
            }
            .scaleEffect(shown ? 1 : 0.2)
            .rotationEffect(.degrees(shown ? -4 : -24))
            .opacity(shown ? 1 : 0)
        }
        .overlay {
            if praise.tier >= 5 {
                ConfettiView(count: 26, duration: 1.6, spread: 320)
            }
        }
        .allowsHitTesting(false)
        .accessibilityLabel(praise.text)
        .onAppear {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.5)) { shown = true }
            withAnimation(.linear(duration: 1.3)) { spin = true }
        }
    }

    private func outlined(_ text: Text) -> some View {
        let o = style.outline
        return text
            .foregroundStyle(LinearGradient(colors: style.fill, startPoint: .top, endPoint: .bottom))
            .shadow(color: o, radius: 0, x: 2, y: 2)
            .shadow(color: o, radius: 0, x: -2, y: 2)
            .shadow(color: o, radius: 0, x: 2, y: -2)
            .shadow(color: o, radius: 0, x: -2, y: -2)
            .shadow(color: .black.opacity(0.3), radius: 6, y: 5)
    }
}

/// Soft rays behind the praise word.
struct SunRays: View {
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let cx = Double(size.width) / 2, cy = Double(size.height) / 2
            let c = CGPoint(x: cx, y: cy)
            let r = Double(min(size.width, size.height)) / 2
            for k in 0..<16 {
                let a = Double(k) / 16 * 2 * .pi
                var ray = Path()
                ray.move(to: c)
                ray.addLine(to: CGPoint(x: cx + cos(a - 0.09) * r, y: cy + sin(a - 0.09) * r))
                ray.addLine(to: CGPoint(x: cx + cos(a + 0.09) * r, y: cy + sin(a + 0.09) * r))
                ray.closeSubpath()
                ctx.fill(ray, with: .radialGradient(Gradient(colors: [color, color.opacity(0)]), center: c, startRadius: 0, endRadius: r))
            }
        }
    }
}

/// Petals, leaves and stars falling for `duration` seconds, then gone.
struct ConfettiView: View {
    var count = 60
    var duration: Double = 3
    var spread: CGFloat? = nil       // nil: the full width

    @State private var start = Date()
    private static let colors: [Color] = [Theme.blossom, Theme.sunshine, .white, Color(hex: 0x9BE15D), Color(hex: 0x7FD1FF), Color(hex: 0xFF9E5E)]

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSince(start)
            Canvas { ctx, size in
                guard t < duration + 1 else { return }
                let width = Double(spread ?? size.width)
                let left = (Double(size.width) - width) / 2
                for i in 0..<count {
                    let r1 = unit(i, 1), r2 = unit(i, 2), r3 = unit(i, 3)
                    let delay = r1 * duration * 0.35
                    let local = t - delay
                    guard local > 0 else { continue }
                    let fall = 160 + r2 * 220
                    let x = left + r3 * width + sin(local * (2 + r1 * 3) + Double(i)) * 24
                    let y = -20 + local * fall
                    guard y < Double(size.height) + 20 else { continue }
                    let fade = max(0, min(1, (duration + 0.6 - local) / 0.6))
                    var p = ctx
                    p.opacity = fade
                    p.translateBy(x: x, y: y)
                    p.rotate(by: .radians(local * (3 + r2 * 4)))
                    p.scaleBy(x: cos(local * (4 + r3 * 5)), y: 1)
                    let color = Self.colors[i % Self.colors.count]
                    if i % 3 == 0 {
                        var leaf = Path()
                        leaf.move(to: CGPoint(x: -7, y: 0))
                        leaf.addQuadCurve(to: CGPoint(x: 7, y: 0), control: CGPoint(x: 0, y: -6))
                        leaf.addQuadCurve(to: CGPoint(x: -7, y: 0), control: CGPoint(x: 0, y: 6))
                        p.fill(leaf, with: .color(color))
                    } else {
                        p.fill(Path(ellipseIn: CGRect(x: -6, y: -3.5, width: 12, height: 7)), with: .color(color))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { start = Date() }
    }

    private func unit(_ i: Int, _ salt: Int) -> Double {
        let x = sin(Double(i) * 12.9898 + Double(salt) * 78.233) * 43_758.5453
        return x - floor(x)
    }
}

/// Shows the running combo and how long is left to keep it.
struct ComboMeter: View {
    let combo: Int
    let lastMatchAt: Date?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let left = lastMatchAt.map { max(0, 1 - context.date.timeIntervalSince($0) / GameModel.comboWindow) } ?? 0
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(LinearGradient(colors: [Theme.sunshine, Color(hex: 0xFF6B3D)], startPoint: .top, endPoint: .bottom))
                Text("Combo ×\(combo)")
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.leafDeep)
                    .monospacedDigit()
                GeometryReader { geo in
                    Capsule().fill(.white.opacity(0.5))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(LinearGradient(colors: [Color(hex: 0x9BE15D), Theme.sunshine], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * left)
                        }
                }
                .frame(height: 10)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(.ultraThinMaterial))
            .opacity(combo >= 1 && left > 0 ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: left > 0)
        }
        .frame(height: 34)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
