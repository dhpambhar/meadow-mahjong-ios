import SwiftUI

/// One mahjong tile: an ivory face over a jade back, drawn in code.
/// `size` is the tile's whole cell, the visible thickness included.
struct TileView: View {
    let face: TileFace
    let size: CGSize
    var isSelected = false
    var isHinted = false
    var isDimmed = false

    var body: some View {
        let depth = size.width * 0.09
        let faceSize = CGSize(width: size.width - depth, height: size.height - depth)
        let radius = size.width * 0.14
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        ZStack(alignment: .topLeading) {
            // Thickness: jade back, then the bone layer, light from the top left.
            shape.fill(Theme.tileSide)
                .frame(width: faceSize.width, height: faceSize.height)
                .offset(x: depth, y: depth)
            shape.fill(Theme.tileEdge)
                .frame(width: faceSize.width, height: faceSize.height)
                .offset(x: depth * 0.45, y: depth * 0.45)

            ZStack {
                shape.fill(LinearGradient(
                    colors: isSelected ? [Theme.tileSelectedTop, Theme.tileSelectedBottom] : [Theme.tileFaceTop, Theme.tileFaceBottom],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                shape.strokeBorder(.white.opacity(0.9), lineWidth: max(1, size.width * 0.025))
                TileGlyph(face: face)
                    .padding(.horizontal, faceSize.width * 0.1)
                    .padding(.vertical, faceSize.height * 0.08)
                if isDimmed {
                    shape.fill(Color(hex: 0x2B3A2F).opacity(0.32))
                }
                if isSelected {
                    shape.strokeBorder(Theme.selection, lineWidth: max(2.5, size.width * 0.07))
                }
                if isHinted {
                    shape.strokeBorder(Theme.hint, lineWidth: max(3, size.width * 0.08))
                        .phaseAnimator([0.25, 1.0]) { content, glow in
                            content.opacity(glow).shadow(color: Theme.hint.opacity(glow), radius: 8 * glow)
                        } animation: { _ in .easeInOut(duration: 0.55) }
                }
            }
            .frame(width: faceSize.width, height: faceSize.height)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .compositingGroup()
        .shadow(color: .black.opacity(0.28), radius: size.width * 0.05, x: size.width * 0.03, y: size.width * 0.05)
        .accessibilityElement()
        .accessibilityLabel(face.accessibilityName)
    }
}

/// The picture on a tile.
struct TileGlyph: View {
    let face: TileFace

    private static let numerals = ["一", "二", "三", "四", "五", "六", "七", "八", "九"]

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            Group {
                switch face.suit {
                case .dots:
                    Canvas { ctx, size in DotsPainter.paint(rank: face.rank, in: &ctx, size: size) }
                case .bamboo where face.rank == 1:
                    symbol("leaf.fill", Theme.glyphGreen, scale: 0.8)
                case .bamboo:
                    Canvas { ctx, size in BambooPainter.paint(rank: face.rank, in: &ctx, size: size) }
                case .characters:
                    VStack(spacing: -h * 0.04) {
                        Text(Self.numerals[face.rank - 1])
                            .font(.system(size: h * 0.36, weight: .heavy))
                            .foregroundStyle(Theme.glyphNavy)
                        Text("萬")
                            .font(.system(size: h * 0.42, weight: .heavy))
                            .foregroundStyle(Theme.glyphRed)
                    }
                    .overlay(alignment: .topLeading) { corner("\(face.rank)", h) }
                case .wind:
                    Text(["東", "南", "西", "北"][face.rank - 1])
                        .font(.system(size: h * 0.6, weight: .heavy))
                        .foregroundStyle(Theme.glyphNavy)
                        .overlay(alignment: .topLeading) { corner(["E", "S", "W", "N"][face.rank - 1], h) }
                case .dragon:
                    dragon(h)
                case .nature:
                    symbol(["camera.macro", "ladybug.fill", "bird.fill", "tortoise.fill"][face.rank - 1],
                           [Color(hex: 0xE8457A), Color(hex: 0xD9332B), Color(hex: 0x2E86C1), Color(hex: 0x3E8E41)][face.rank - 1])
                case .season:
                    symbol(["sun.max.fill", "cloud.rain.fill", "leaf.fill", "snowflake"][face.rank - 1],
                           [Color(hex: 0xF29A1D), Color(hex: 0x4A7FC1), Color(hex: 0xD9622B), Color(hex: 0x5AA9E6)][face.rank - 1])
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .minimumScaleFactor(0.5)
        }
    }

    private func symbol(_ name: String, _ color: Color, scale: CGFloat = 0.85) -> some View {
        Image(systemName: name)
            .resizable()
            .scaledToFit()
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .scaleEffect(scale)
    }

    /// Small Latin index, so players who don't read the characters can still tell tiles apart.
    private func corner(_ text: String, _ h: CGFloat) -> some View {
        Text(text)
            .font(.system(size: h * 0.17, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.glyphNavy.opacity(0.7))
            .offset(x: -h * 0.08, y: -h * 0.04)
    }

    @ViewBuilder
    private func dragon(_ h: CGFloat) -> some View {
        switch face.rank {
        case 1:
            Text("中").font(.system(size: h * 0.62, weight: .heavy)).foregroundStyle(Theme.glyphRed)
        case 2:
            Text("發").font(.system(size: h * 0.6, weight: .heavy)).foregroundStyle(Theme.glyphGreen)
        default:
            RoundedRectangle(cornerRadius: h * 0.08)
                .strokeBorder(Theme.glyphBlue, lineWidth: h * 0.06)
                .overlay(RoundedRectangle(cornerRadius: h * 0.05).strokeBorder(Theme.glyphBlue.opacity(0.6), lineWidth: h * 0.025).padding(h * 0.08))
                .padding(.horizontal, h * 0.06)
                .padding(.vertical, h * 0.04)
        }
    }
}

// MARK: - Painters

private enum DotsPainter {
    /// Dot centres in a unit square, for 1 to 9.
    static let layouts: [[CGPoint]] = [
        [p(0.5, 0.5)],
        [p(0.5, 0.25), p(0.5, 0.75)],
        [p(0.24, 0.18), p(0.5, 0.5), p(0.76, 0.82)],
        [p(0.27, 0.25), p(0.73, 0.25), p(0.27, 0.75), p(0.73, 0.75)],
        [p(0.25, 0.2), p(0.75, 0.2), p(0.5, 0.5), p(0.25, 0.8), p(0.75, 0.8)],
        [p(0.28, 0.18), p(0.72, 0.18), p(0.28, 0.5), p(0.72, 0.5), p(0.28, 0.82), p(0.72, 0.82)],
        [p(0.2, 0.12), p(0.5, 0.25), p(0.8, 0.38), p(0.28, 0.62), p(0.72, 0.62), p(0.28, 0.87), p(0.72, 0.87)],
        [p(0.28, 0.12), p(0.72, 0.12), p(0.28, 0.37), p(0.72, 0.37), p(0.28, 0.63), p(0.72, 0.63), p(0.28, 0.88), p(0.72, 0.88)],
        [p(0.2, 0.17), p(0.5, 0.17), p(0.8, 0.17), p(0.2, 0.5), p(0.5, 0.5), p(0.8, 0.5), p(0.2, 0.83), p(0.5, 0.83), p(0.8, 0.83)],
    ]

    static func paint(rank: Int, in ctx: inout GraphicsContext, size: CGSize) {
        let points = layouts[rank - 1]
        let unit = min(size.width, size.height)
        let r = unit * (rank == 1 ? 0.36 : rank <= 4 ? 0.19 : rank <= 6 ? 0.15 : 0.13)
        let colors = [Theme.glyphBlue, Theme.glyphGreen, Theme.glyphRed]
        for (i, point) in points.enumerated() {
            let c = CGPoint(x: point.x * size.width, y: point.y * size.height)
            let color = rank == 1 ? Theme.glyphRed : colors[(i + rank) % colors.count]
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(color))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.62, y: c.y - r * 0.62, width: r * 1.24, height: r * 1.24)), with: .color(.white))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.38, y: c.y - r * 0.38, width: r * 0.76, height: r * 0.76)), with: .color(color))
        }
    }
}

private enum BambooPainter {
    /// Stick centres in a unit square, for 2 to 9. Index 0 is unused (1 bamboo is a leaf).
    static let layouts: [[CGPoint]] = [
        [],
        [p(0.5, 0.27), p(0.5, 0.73)],
        [p(0.5, 0.27), p(0.3, 0.73), p(0.7, 0.73)],
        [p(0.3, 0.27), p(0.7, 0.27), p(0.3, 0.73), p(0.7, 0.73)],
        [p(0.22, 0.27), p(0.78, 0.27), p(0.5, 0.5), p(0.22, 0.73), p(0.78, 0.73)],
        [p(0.22, 0.27), p(0.5, 0.27), p(0.78, 0.27), p(0.22, 0.73), p(0.5, 0.73), p(0.78, 0.73)],
        [p(0.5, 0.17), p(0.22, 0.5), p(0.5, 0.5), p(0.78, 0.5), p(0.22, 0.83), p(0.5, 0.83), p(0.78, 0.83)],
        [p(0.17, 0.27), p(0.39, 0.27), p(0.61, 0.27), p(0.83, 0.27), p(0.17, 0.73), p(0.39, 0.73), p(0.61, 0.73), p(0.83, 0.73)],
        [p(0.22, 0.17), p(0.5, 0.17), p(0.78, 0.17), p(0.22, 0.5), p(0.5, 0.5), p(0.78, 0.5), p(0.22, 0.83), p(0.5, 0.83), p(0.78, 0.83)],
    ]

    static func paint(rank: Int, in ctx: inout GraphicsContext, size: CGSize) {
        let points = layouts[rank - 1]
        let rows = rank >= 7 && rank != 8 ? 3.0 : 2.0
        let stickH = size.height / rows * 0.8
        let stickW = min(size.width * (rank == 8 ? 0.13 : 0.16), stickH * 0.36)
        for (i, point) in points.enumerated() {
            // The middle stick of 5, 7 and 9 is red, as on real sets.
            let isRed = (rank == 5 && i == 2) || (rank == 7 && i == 0) || (rank == 9 && i % 3 == 1)
            let color = isRed ? Theme.glyphRed : Theme.glyphGreen
            let rect = CGRect(x: point.x * size.width - stickW / 2, y: point.y * size.height - stickH / 2, width: stickW, height: stickH)
            ctx.fill(Path(roundedRect: rect, cornerRadius: stickW / 2), with: .color(color))
            let joint = CGRect(x: rect.minX - stickW * 0.12, y: rect.midY - stickW * 0.12, width: stickW * 1.24, height: stickW * 0.24)
            ctx.fill(Path(roundedRect: joint, cornerRadius: stickW * 0.12), with: .color(color.opacity(0.75)))
            ctx.fill(Path(CGRect(x: rect.midX - stickW * 0.12, y: rect.minY + stickH * 0.12, width: stickW * 0.24, height: stickH * 0.76)),
                     with: .color(.white.opacity(0.45)))
        }
    }
}

private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }
