#!/usr/bin/env swift
// Renders Resources/AppIcon.icns. Run only when the icon design changes:
//   swift scripts/make-icon.swift
//
// The icon exists because Notification Center shows the posting app's icon on
// every banner; without one the translations arrive under a blank placeholder.
import AppKit

let sizes = [16, 32, 64, 128, 256, 512, 1024]
let outputDirectory = URL(fileURLWithPath: "Resources/AppIcon.iconset")
try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

func render(size: Int) -> Data {
    let side = CGFloat(size)
    let image = NSImage(size: NSSize(width: side, height: side))
    image.lockFocus()

    let inset = side * 0.06
    let body = NSRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
    let squircle = NSBezierPath(roundedRect: body,
                                xRadius: side * 0.225, yRadius: side * 0.225)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.16, green: 0.44, blue: 0.94, alpha: 1),
        NSColor(calibratedRed: 0.35, green: 0.24, blue: 0.86, alpha: 1),
    ])?.draw(in: squircle, angle: -90)

    let glyph = "譯" as NSString
    let fontSize = side * 0.58
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
        .foregroundColor: NSColor.white,
    ]
    let bounds = glyph.size(withAttributes: attributes)
    glyph.draw(
        at: NSPoint(x: (side - bounds.width) / 2, y: (side - bounds.height) / 2),
        withAttributes: attributes)

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:])
    else { fatalError("failed to render \(size)px") }
    return png
}

for size in sizes {
    let png = render(size: size)
    try png.write(to: outputDirectory.appendingPathComponent("icon_\(size)x\(size).png"))
    if size <= 512 {
        let retina = render(size: size * 2)
        try retina.write(to: outputDirectory.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
    }
}
print("wrote \(outputDirectory.path)")
