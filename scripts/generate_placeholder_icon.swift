import AppKit

let size: CGFloat = 1024
let rect = NSRect(x: 0, y: 0, width: size, height: size)

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.12, green: 0.57, blue: 0.95, alpha: 1),
    NSColor(calibratedRed: 0.10, green: 0.74, blue: 0.50, alpha: 1)
])!
gradient.draw(in: rect, angle: -45)

let text = "DD"
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 380, weight: .bold),
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraph
]

let textRect = NSRect(x: 0, y: 250, width: size, height: 500)
text.draw(in: textRect, withAttributes: attrs)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not create PNG")
}

let outputPath = "/Users/i589273/Desktop/Privat/Project2026/DoneDaily/DoneDaily/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote: \(outputPath)")
