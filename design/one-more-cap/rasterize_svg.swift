import AppKit

guard CommandLine.arguments.count == 4 else {
    fputs("Usage: rasterize_svg.swift <input.svg> <output.png> <size>\n", stderr)
    exit(2)
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
guard let size = Int(CommandLine.arguments[3]), size > 0 else {
    fputs("Size must be a positive integer.\n", stderr)
    exit(2)
}

guard let image = NSImage(contentsOf: inputURL) else {
    fputs("Could not load SVG: \(inputURL.path)\n", stderr)
    exit(1)
}

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Could not create bitmap context.\n", stderr)
    exit(1)
}

rep.size = NSSize(width: size, height: size)
if let data = rep.bitmapData {
    data.initialize(repeating: 0, count: rep.bytesPerRow * rep.pixelsHigh)
}
NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: rep)
NSGraphicsContext.current = context
context?.cgContext.clear(CGRect(x: 0, y: 0, width: size, height: size))
image.draw(
    in: NSRect(x: 0, y: 0, width: size, height: size),
    from: .zero,
    operation: .sourceOver,
    fraction: 1
)
NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else {
    fputs("Could not encode PNG.\n", stderr)
    exit(1)
}

do {
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try data.write(to: outputURL)
} catch {
    fputs("Could not write PNG: \(error)\n", stderr)
    exit(1)
}
