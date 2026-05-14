import SwiftUI

// MARK: - Full Screen Elephant Background

struct FullScreenElephantBackground: View {
    var body: some View {
        GeometryReader { geo in
            let bleed: CGFloat = 48

            Image("MARSHALL ELEPHANT")
                .resizable(resizingMode: .tile)
                .frame(width: geo.size.width + bleed * 2, height: geo.size.height + bleed * 2)
                .scaleEffect(x: 1.15, y: 1.15, anchor: .center)
                .brightness(0.08)
                .saturation(1.05)
                .overlay(Color.black.opacity(0.18))
                .offset(x: -bleed, y: -bleed)
        }
    }
}

// MARK: - Marshall Elephant Overlay (with hole cutout)

struct MarshallElephantOverlay: View {
    let canvasSize: CGSize
    let highlightWidth: CGFloat
    let highlightHeight: CGFloat
    let highlightCenter: CGPoint
    let highlightCornerRadius: CGFloat
    var textureBrightness: Double = 0.12
    var textureOverlayOpacity: Double = 0.2
    var textureBleed: CGFloat = 36

    var body: some View {
        let bleed = textureBleed

        Image("MARSHALL ELEPHANT")
            .resizable(resizingMode: .tile)
            .frame(width: canvasSize.width + (bleed * 2), height: canvasSize.height + (bleed * 2))
            .scaleEffect(x: 1.15, y: 1.15, anchor: .center)
            .brightness(textureBrightness)
            .saturation(1.05)
            .overlay(Color.black.opacity(textureOverlayOpacity))
            .offset(x: -bleed, y: -bleed)
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
        .mask(maskShape)
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private var maskShape: some View {
        Rectangle()
            .frame(width: canvasSize.width, height: canvasSize.height)
            .overlay {
                HighlightWindowShape(cornerRadius: highlightCornerRadius)
                    .frame(width: highlightWidth, height: highlightHeight)
                    .position(x: highlightCenter.x, y: highlightCenter.y)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }
}

// MARK: - Elephant Window View (elephant + gold border combined)

struct ElephantWindowView: View {
    let canvasSize: CGSize
    let highlightWidth: CGFloat
    let highlightHeight: CGFloat
    let highlightCenter: CGPoint
    let highlightCornerRadius: CGFloat
    var textureBrightness: Double = 0.12
    var textureOverlayOpacity: Double = 0.2
    var textureBleed: CGFloat = 36

    var body: some View {
        ZStack {
            // Elephant with the hole cut out
            MarshallElephantOverlay(
                canvasSize: canvasSize,
                highlightWidth: highlightWidth,
                highlightHeight: highlightHeight,
                highlightCenter: highlightCenter,
                highlightCornerRadius: highlightCornerRadius,
                textureBrightness: textureBrightness,
                textureOverlayOpacity: textureOverlayOpacity,
                textureBleed: textureBleed
            )
            
            // Gold border drawn in the exact same position as the hole
            HighlightWindowGoldBorder(
                width: highlightWidth,
                height: highlightHeight,
                cornerRadius: highlightCornerRadius
            )
            .position(x: highlightCenter.x, y: highlightCenter.y)
        }
    }
}

// MARK: - Highlight Window Gold Border

struct HighlightWindowGoldBorder: View {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        HighlightWindowShape(cornerRadius: cornerRadius)
            .strokeBorder(
                LinearGradient(
                    colors: [.goldBorderMid, .goldBorderDark, .goldBorderLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 4
            )
            .frame(width: width, height: height)
    }
}

// MARK: - Dark Matte Overlay

struct DarkMatteOverlay: View {
    let canvasSize: CGSize
    let highlightWidth: CGFloat
    let highlightHeight: CGFloat
    let highlightCenter: CGPoint
    let highlightCornerRadius: CGFloat

    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
                .frame(width: canvasSize.width, height: canvasSize.height)

            RoundedRectangle(cornerRadius: highlightCornerRadius, style: .continuous)
                .fill(Color.black)
                .frame(width: highlightWidth, height: highlightHeight)
                .position(x: highlightCenter.x, y: highlightCenter.y)
                .blendMode(.destinationOut)
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .compositingGroup()
        .allowsHitTesting(false)
    }
}

// MARK: - Full Screen Tweed Background

struct FullScreenTweedBackground: View {
    /// Optional window cutout. When provided, a hole is punched at the given
    /// safe-area-relative center so the single image render covers everything
    /// outside the window without a second overlapping tweed layer.
    var windowCutout: (center: CGPoint, width: CGFloat, height: CGFloat, cornerRadius: CGFloat)? = nil
    /// Extra safe-area inset to add to windowCutout.center when the GeometryReader
    /// measures the full screen (ignoresSafeArea) but the center is in safe-area coords.
    var safeAreaInsets: EdgeInsets = .init()

    var body: some View {
        GeometryReader { geo in
            let bleed: CGFloat = 48

            let tweedImage = Image("tweed set two")
                .resizable()
                .frame(width: geo.size.width + bleed * 2, height: geo.size.height + bleed * 2)
                .scaleEffect(x: 1.15, y: -1.15, anchor: .center)
                .brightness(0.08)
                .saturation(1.05)
                .overlay(Color.black.opacity(0.18))
                .offset(x: -bleed, y: -bleed)

            if let cutout = windowCutout {
                let holeCenterX = safeAreaInsets.leading + cutout.center.x
                let holeCenterY = safeAreaInsets.top + cutout.center.y
                tweedImage
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .mask(
                        Rectangle()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .overlay {
                                HighlightWindowShape(cornerRadius: cutout.cornerRadius)
                                    .frame(width: cutout.width, height: cutout.height)
                                    .position(x: holeCenterX, y: holeCenterY)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                    )
            } else {
                tweedImage
            }
        }
    }
}

// MARK: - Tweed Overlay (with hole cutout)

struct TweedOverlay: View {
    let canvasSize: CGSize
    let highlightWidth: CGFloat
    let highlightHeight: CGFloat
    let highlightCenter: CGPoint
    let highlightCornerRadius: CGFloat
    var textureBrightness: Double = 0.12
    var textureOverlayOpacity: Double = 0.2
    var textureBleed: CGFloat = 36

    var body: some View {
        let bleed = textureBleed

        Image("tweed set two")
            .resizable()
            .frame(width: canvasSize.width + (bleed * 2), height: canvasSize.height + (bleed * 2))
            .scaleEffect(x: 1.15, y: -1.15, anchor: .center)
            .brightness(textureBrightness)
            .saturation(1.05)
            .overlay(Color.black.opacity(textureOverlayOpacity))
            .offset(x: -bleed, y: -bleed)
        .frame(width: canvasSize.width, height: canvasSize.height)
        .clipped()
        .mask(maskShape)
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private var maskShape: some View {
        Rectangle()
            .frame(width: canvasSize.width, height: canvasSize.height)
            .overlay {
                HighlightWindowShape(cornerRadius: highlightCornerRadius)
                    .frame(width: highlightWidth, height: highlightHeight)
                    .position(x: highlightCenter.x, y: highlightCenter.y)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }
}

// MARK: - Tweed Window View (tweed + chrome border combined)

struct TweedWindowView: View {
    let canvasSize: CGSize
    let highlightWidth: CGFloat
    let highlightHeight: CGFloat
    let highlightCenter: CGPoint
    let highlightCornerRadius: CGFloat
    var textureBrightness: Double = 0.12
    var textureOverlayOpacity: Double = 0.2
    var textureBleed: CGFloat = 36

    var body: some View {
        ZStack {
            // Tweed with the hole cut out
            TweedOverlay(
                canvasSize: canvasSize,
                highlightWidth: highlightWidth,
                highlightHeight: highlightHeight,
                highlightCenter: highlightCenter,
                highlightCornerRadius: highlightCornerRadius,
                textureBrightness: textureBrightness,
                textureOverlayOpacity: textureOverlayOpacity,
                textureBleed: textureBleed
            )

            // Chrome border drawn in the exact same position as the hole
            HighlightWindowChromeBorder(
                width: highlightWidth,
                height: highlightHeight,
                cornerRadius: highlightCornerRadius
            )
            .position(x: highlightCenter.x, y: highlightCenter.y)
        }
    }
}

// MARK: - Highlight Window Chrome Border

struct HighlightWindowChromeBorder: View {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        HighlightWindowShape(cornerRadius: cornerRadius)
            .strokeBorder(Color.white, lineWidth: 4)
            .frame(width: width, height: height)
    }
}
