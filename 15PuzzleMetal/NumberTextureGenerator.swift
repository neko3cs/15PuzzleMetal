//
//  NumberTextureGenerator.swift
//  15PuzzleMetal
//

import Metal
import CoreGraphics
import AppKit

class NumberTextureGenerator {
    static func generate(device: MTLDevice, size: Int = 1024) -> MTLTexture? {
        let width = size
        let height = size
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            return nil
        }
        
        // --- Vivid Theme Colors ---
        let tileColors: [NSColor] = [
            NSColor(calibratedRed: 1.0,  green: 0.1,  blue: 0.1,  alpha: 1.0), // Vivid Red
            NSColor(calibratedRed: 0.1,  green: 0.9,  blue: 0.1,  alpha: 1.0), // Vivid Green
            NSColor(calibratedRed: 0.1,  green: 0.4,  blue: 1.0,  alpha: 1.0), // Vivid Blue
            NSColor(calibratedRed: 0.9,  green: 0.1,  blue: 0.9,  alpha: 1.0), // Vivid Magenta
            NSColor(calibratedRed: 1.0,  green: 0.6,  blue: 0.0,  alpha: 1.0)  // Vivid Orange
        ]
        
        // Fill overall texture background with transparency
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        
        let tileSize = width / 4
        let cornerRadius: CGFloat = CGFloat(tileSize) * 0.15
        
        for i in 0..<16 {
            let number = i + 1
            if number > 15 { continue }
            
            let row = i / 4
            let col = i % 4
            
            // Draw tile background with rounded corners
            let rect = CGRect(x: col * tileSize, y: (3 - row) * tileSize, width: tileSize, height: tileSize)
            let tileRect = rect.insetBy(dx: 12, dy: 12)
            
            // CoreGraphics drawing for smooth edges
            let path = CGPath(roundedRect: tileRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            
            // Pick a color
            let colorIndex = (row + col) % tileColors.count
            
            context.saveGState()
            // Add shadow
            context.setShadow(offset: CGSize(width: 4, height: -4), blur: 12, color: NSColor.black.withAlphaComponent(0.6).cgColor)
            context.setFillColor(tileColors[colorIndex].cgColor)
            context.addPath(path)
            context.fillPath()
            context.restoreGState()
            
            // Draw tile border
            context.setStrokeColor(NSColor.white.withAlphaComponent(0.9).cgColor)
            context.setLineWidth(6.0)
            context.addPath(path)
            context.strokePath()
            
            // Draw number
            let text = "\(number)"
            let fontSize = CGFloat(tileSize) * 0.5
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: NSColor.white,
                .strokeWidth: -2.0, // Thicker font
                .strokeColor: NSColor.black.withAlphaComponent(0.3)
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedString.size()
            
            let textX = tileRect.midX - textSize.width / 2
            let textY = tileRect.midY - textSize.height / 2
            
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            attributedString.draw(at: CGPoint(x: textX, y: textY))
            NSGraphicsContext.restoreGraphicsState()
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                         width: width,
                                                                         height: height,
                                                                         mipmapped: false)
        textureDescriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            return nil
        }
        
        texture.replace(region: MTLRegionMake2D(0, 0, width, height),
                        mipmapLevel: 0,
                        withBytes: context.data!,
                        bytesPerRow: bytesPerRow)
        
        return texture
    }
}

// Extension to bridge NSBezierPath to CGPath easily
extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        return path
    }
}
