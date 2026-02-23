import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
let rect = NSRect(x: 0, y: 0, width: size, height: size)

image.lockFocus()

NSColor(calibratedRed: 0.95, green: 0.97, blue: 1.0, alpha: 1).setFill()
rect.fill()

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.06, green: 0.48, blue: 0.95, alpha: 1),
    NSColor(calibratedRed: 0.14, green: 0.74, blue: 0.54, alpha: 1)
])!

let roundedRect = NSBezierPath(
    roundedRect: NSRect(x: 112, y: 112, width: 800, height: 800),
    xRadius: 180,
    yRadius: 180
)
gradient.draw(in: roundedRect, angle: -35)

let ring = NSBezierPath(
    roundedRect: NSRect(x: 220, y: 220, width: 584, height: 584),
    xRadius: 130,
    yRadius: 130
)
NSColor.white.withAlphaComponent(0.2).setStroke()
ring.lineWidth = 24
ring.stroke()

let checkPath = NSBezierPath()
checkPath.move(to: NSPoint(x: 330, y: 510))
checkPath.line(to: NSPoint(x: 470, y: 360))
checkPath.line(to: NSPoint(x: 700, y: 650))
NSColor.white.setStroke()
checkPath.lineWidth = 68
checkPath.lineCapStyle = .round
checkPath.lineJoinStyle = .round
checkPath.stroke()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not create PNG")
}

let outputPath = "/Users/i589273/Desktop/Privat/Project2026/DoneDaily/DoneDaily/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote: \(outputPath)")
