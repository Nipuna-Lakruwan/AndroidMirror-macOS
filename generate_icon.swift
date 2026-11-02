//
//  generate_icon.swift
//  AndroidMirror
//
//  Change Description:
//  Author: Nipuna Lakruwan
//  Date: 2026-11-02
//  Previous Code: File did not exist (new creation).
//  Added Code: Created standalone Swift script to procedurally render an Apple-style
//              macOS squircle application icon for Android Mirror using CoreGraphics and AppKit.
//              Generates complete .iconset directory and invokes iconutil to produce AppIcon.icns.
//  How: Uses NSGraphicsContext, CGContext gradients, bezier paths, and image resizing.
//

import AppKit
import Foundation

func renderMasterIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    let scale = size / 1024.0

    // 1. Base Squircle Dimensions
    let squircleInset: CGFloat = 100.0 * scale
    let squircleRect = CGRect(
        x: squircleInset,
        y: squircleInset,
        width: size - (squircleInset * 2),
        height: size - (squircleInset * 2)
    )
    let cornerRadius: CGFloat = 185.0 * scale

    // Background Drop Shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -18.0 * scale),
        blur: 32.0 * scale,
        color: NSColor.black.withAlphaComponent(0.35).cgColor
    )

    let squirclePath = CGPath(
        roundedRect: squircleRect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    )
    ctx.addPath(squirclePath)
    ctx.fillPath()
    ctx.restoreGState()

    // Base Gradient (Vibrant Apple-style Sky Blue to Royal Indigo/Cyan)
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(calibratedRed: 0.38, green: 0.72, blue: 0.98, alpha: 1.0).cgColor, // Vibrant Sky Blue
        NSColor(calibratedRed: 0.30, green: 0.52, blue: 0.95, alpha: 1.0).cgColor, // Royal Blue
        NSColor(calibratedRed: 0.36, green: 0.38, blue: 0.88, alpha: 1.0).cgColor  // Indigo Accent
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.55, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(
            bgGradient,
            start: CGPoint(x: squircleRect.midX, y: squircleRect.maxY),
            end: CGPoint(x: squircleRect.midX, y: squircleRect.minY),
            options: []
        )
    }

    // Inner subtle glow/border
    ctx.addPath(squirclePath)
    ctx.setLineWidth(2.5 * scale)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.28).cgColor)
    ctx.strokePath()

    // 2. Back Phone: The Physical Android Phone (Dark Titanium, Locked)
    let backPhoneWidth: CGFloat = 265.0 * scale
    let backPhoneHeight: CGFloat = 530.0 * scale
    let backPhoneX: CGFloat = 300.0 * scale
    let backPhoneY: CGFloat = 270.0 * scale
    let backPhoneCorner: CGFloat = 52.0 * scale

    let backPhoneRect = CGRect(x: backPhoneX, y: backPhoneY, width: backPhoneWidth, height: backPhoneHeight)
    let backPhonePath = CGPath(
        roundedRect: backPhoneRect,
        cornerWidth: backPhoneCorner,
        cornerHeight: backPhoneCorner,
        transform: nil
    )

    // Back Phone Shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: -8.0 * scale, height: -12.0 * scale),
        blur: 24.0 * scale,
        color: NSColor.black.withAlphaComponent(0.40).cgColor
    )
    ctx.addPath(backPhonePath)
    ctx.fillPath()
    ctx.restoreGState()

    // Back Phone Gradient (Dark Slate/Obsidian)
    ctx.saveGState()
    ctx.addPath(backPhonePath)
    ctx.clip()

    let backColors = [
        NSColor(calibratedRed: 0.16, green: 0.19, blue: 0.27, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.11, green: 0.13, blue: 0.18, alpha: 1.0).cgColor
    ] as CFArray
    if let backGradient = CGGradient(colorsSpace: colorSpace, colors: backColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(
            backGradient,
            start: CGPoint(x: backPhoneRect.midX, y: backPhoneRect.maxY),
            end: CGPoint(x: backPhoneRect.midX, y: backPhoneRect.minY),
            options: []
        )
    }

    // Android Center Punch-Hole Camera on back phone
    let backCamRadius: CGFloat = 6.0 * scale
    let backCamCenter = CGPoint(x: backPhoneRect.midX, y: backPhoneRect.maxY - (28.0 * scale))
    ctx.addArc(center: backCamCenter, radius: backCamRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
    ctx.setFillColor(NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.10, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Back Phone Border
    ctx.addPath(backPhonePath)
    ctx.setLineWidth(2.0 * scale)
    ctx.setStrokeColor(NSColor(calibratedRed: 0.28, green: 0.32, blue: 0.42, alpha: 0.6).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    // 3. Front Phone: The Mirrored Screen (Frosted White, Active Android UI)
    let frontPhoneWidth: CGFloat = 265.0 * scale
    let frontPhoneHeight: CGFloat = 530.0 * scale
    let frontPhoneX: CGFloat = 455.0 * scale
    let frontPhoneY: CGFloat = 220.0 * scale
    let frontPhoneCorner: CGFloat = 52.0 * scale

    let frontPhoneRect = CGRect(x: frontPhoneX, y: frontPhoneY, width: frontPhoneWidth, height: frontPhoneHeight)
    let frontPhonePath = CGPath(
        roundedRect: frontPhoneRect,
        cornerWidth: frontPhoneCorner,
        cornerHeight: frontPhoneCorner,
        transform: nil
    )

    // Front Phone Drop Shadow
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: -12.0 * scale, height: -16.0 * scale),
        blur: 36.0 * scale,
        color: NSColor(calibratedRed: 0.08, green: 0.12, blue: 0.28, alpha: 0.45).cgColor
    )
    ctx.addPath(frontPhonePath)
    ctx.fillPath()
    ctx.restoreGState()

    // Front Phone Glass Body
    ctx.saveGState()
    ctx.addPath(frontPhonePath)
    ctx.clip()

    let frontColors = [
        NSColor(calibratedRed: 0.98, green: 0.99, blue: 1.0, alpha: 0.95).cgColor,
        NSColor(calibratedRed: 0.88, green: 0.92, blue: 0.98, alpha: 0.88).cgColor
    ] as CFArray
    if let frontGradient = CGGradient(colorsSpace: colorSpace, colors: frontColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(
            frontGradient,
            start: CGPoint(x: frontPhoneRect.midX, y: frontPhoneRect.maxY),
            end: CGPoint(x: frontPhoneRect.midX, y: frontPhoneRect.minY),
            options: []
        )
    }

    // Android Center Punch-Hole Camera on front phone
    let frontCamRadius: CGFloat = 6.0 * scale
    let frontCamCenter = CGPoint(x: frontPhoneRect.midX, y: frontPhoneRect.maxY - (28.0 * scale))
    ctx.addArc(center: frontCamCenter, radius: frontCamRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
    ctx.setFillColor(NSColor(calibratedRed: 0.20, green: 0.25, blue: 0.35, alpha: 0.4).cgColor)
    ctx.fillPath()

    // Draw UI Elements: App Grid Icons
    let gridCols = 3
    let gridRows = 4
    let iconSize: CGFloat = 50.0 * scale
    let iconCorner: CGFloat = 14.0 * scale
    let gridSpacingX: CGFloat = 24.0 * scale
    let gridSpacingY: CGFloat = 24.0 * scale
    let totalGridWidth = (CGFloat(gridCols) * iconSize) + (CGFloat(gridCols - 1) * gridSpacingX)
    let gridStartX = frontPhoneRect.midX - (totalGridWidth / 2.0)
    let gridStartY = frontPhoneRect.maxY - (120.0 * scale)

    let iconColors = [
        NSColor(calibratedRed: 0.24, green: 0.58, blue: 0.96, alpha: 0.45), // Android Blue
        NSColor(calibratedRed: 0.20, green: 0.78, blue: 0.45, alpha: 0.45), // Android Green
        NSColor(calibratedRed: 0.98, green: 0.65, blue: 0.20, alpha: 0.45), // Warm Orange
        NSColor(calibratedRed: 0.85, green: 0.30, blue: 0.85, alpha: 0.45), // Purple
        NSColor(calibratedRed: 0.15, green: 0.70, blue: 0.85, alpha: 0.45), // Cyan
        NSColor(calibratedRed: 0.95, green: 0.35, blue: 0.40, alpha: 0.45), // Coral
        NSColor(calibratedRed: 0.20, green: 0.78, blue: 0.45, alpha: 0.45), // Android Green
        NSColor(calibratedRed: 0.24, green: 0.58, blue: 0.96, alpha: 0.45), // Blue
        NSColor(calibratedRed: 0.50, green: 0.40, blue: 0.90, alpha: 0.45), // Deep violet
        NSColor(calibratedRed: 0.30, green: 0.75, blue: 0.50, alpha: 0.45), // Emerald
        NSColor(calibratedRed: 0.98, green: 0.65, blue: 0.20, alpha: 0.45), // Gold
        NSColor(calibratedRed: 0.24, green: 0.58, blue: 0.96, alpha: 0.45), // Blue
    ]

    var colorIdx = 0
    for row in 0..<gridRows {
        for col in 0..<gridCols {
            let x = gridStartX + CGFloat(col) * (iconSize + gridSpacingX)
            let y = gridStartY - CGFloat(row) * (iconSize + gridSpacingY)
            let iconRect = CGRect(x: x, y: y, width: iconSize, height: iconSize)
            let iconPath = CGPath(
                roundedRect: iconRect,
                cornerWidth: iconCorner,
                cornerHeight: iconCorner,
                transform: nil
            )
            ctx.addPath(iconPath)
            ctx.setFillColor(iconColors[colorIdx % iconColors.count].cgColor)
            ctx.fillPath()
            colorIdx += 1
        }
    }

    // Android Bottom Navigation Pill
    let navPillWidth: CGFloat = 85.0 * scale
    let navPillHeight: CGFloat = 5.0 * scale
    let navPillRect = CGRect(
        x: frontPhoneRect.midX - (navPillWidth / 2.0),
        y: frontPhoneRect.minY + (24.0 * scale),
        width: navPillWidth,
        height: navPillHeight
    )
    let navPillPath = CGPath(
        roundedRect: navPillRect,
        cornerWidth: navPillHeight / 2.0,
        cornerHeight: navPillHeight / 2.0,
        transform: nil
    )
    ctx.addPath(navPillPath)
    ctx.setFillColor(NSColor(calibratedRed: 0.25, green: 0.30, blue: 0.42, alpha: 0.35).cgColor)
    ctx.fillPath()

    // Crisp Front Phone Edge Stroke
    ctx.addPath(frontPhonePath)
    ctx.setLineWidth(2.5 * scale)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // End squircle clip

    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, targetSize: Int, fileURL: URL) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: targetSize,
        pixelsHigh: targetSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: targetSize, height: targetSize)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(
        in: NSRect(x: 0, y: 0, width: targetSize, height: targetSize),
        from: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height),
        operation: .copy,
        fraction: 1.0
    )
    NSGraphicsContext.restoreGraphicsState()

    if let pngData = rep.representation(using: .png, properties: [:]) {
        try? pngData.write(to: fileURL)
    }
}

// Main Execution
let scriptDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconsetDir = scriptDir.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconsetDir)
try? FileManager.default.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

print("==> Rendering Master 1024x1024 vector icon...")
let masterImage = renderMasterIcon(size: 1024.0)

let sizes: [(filename: String, pixelSize: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for item in sizes {
    let fileURL = iconsetDir.appendingPathComponent(item.filename)
    savePNG(image: masterImage, targetSize: item.pixelSize, fileURL: fileURL)
}

print("==> Converting iconset to AppIcon.icns via iconutil...")
let icnsURL = scriptDir.appendingPathComponent("AppIcon.icns")
try? FileManager.default.removeItem(at: icnsURL)

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsURL.path]
try? process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("==> Successfully generated AppIcon.icns at: \(icnsURL.path)")
} else {
    print("Failed to generate icns: exit code \(process.terminationStatus)")
}
