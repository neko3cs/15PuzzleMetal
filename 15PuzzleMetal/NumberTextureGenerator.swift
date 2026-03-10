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
        
        // --- Super Vivid Theme Colors ---
        let tileColors: [NSColor] = [
            NSColor(calibratedRed: 1.0,  green: 0.0,  blue: 0.2,  alpha: 1.0), // Deep Pink-Red
            NSColor(calibratedRed: 0.0,  green: 1.0,  blue: 0.1,  alpha: 1.0), // Neon Green
            NSColor(calibratedRed: 0.0,  green: 0.4,  blue: 1.0,  alpha: 1.0), // Electric Blue
            NSColor(calibratedRed: 0.8,  green: 0.0,  blue: 1.0,  alpha: 1.0), // Royal Magenta
            NSColor(calibratedRed: 1.0,  green: 0.5,  blue: 0.0,  alpha: 1.0)  // Bright Orange
        ]
        
        // Fill overall texture background with transparency
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        
        let tileSize = width / 4
        let cornerRadius: CGFloat = CGFloat(tileSize) * 0.18
        
        for i in 0..<16 {
            let number = i + 1
            if number > 15 { continue }
            
            let row = i / 4
            let col = i % 4
            
            // Draw tile background with rounded corners
            let rect = CGRect(x: col * tileSize, y: (3 - row) * tileSize, width: tileSize, height: tileSize)
            let tileRect = rect.insetBy(dx: 12, dy: 12)
            
            let path = CGPath(roundedRect: tileRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            let colorIndex = (row + col) % tileColors.count
            let baseColor = tileColors[colorIndex]
            
            context.saveGState()
            // Add Deeper shadow
            context.setShadow(offset: CGSize(width: 6, height: -6), blur: 15, color: NSColor.black.withAlphaComponent(0.7).cgColor)
            
            // Draw gradient/gloss effect (Linear gradient)
            let colors = [baseColor.cgColor, baseColor.blended(withFraction: 0.3, of: .white)!.cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
            
            context.addPath(path)
            context.clip()
            context.drawLinearGradient(gradient, 
                                       start: CGPoint(x: tileRect.midX, y: tileRect.minY), 
                                       end: CGPoint(x: tileRect.midX, y: tileRect.maxY), 
                                       options: [])
            context.restoreGState()
            
            // Draw tile border (thick & bright)
            context.setStrokeColor(NSColor.white.withAlphaComponent(0.95).cgColor)
            context.setLineWidth(8.0)
            context.addPath(path)
            context.strokePath()
            
            // Draw number with strong shadow
            let text = "\(number)"
            let fontSize = CGFloat(tileSize) * 0.55
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: fontSize),
                .foregroundColor: NSColor.white,
                .strokeWidth: -1.5,
                .strokeColor: NSColor.black.withAlphaComponent(0.4)
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedString.size()
            
            let textX = tileRect.midX - textSize.width / 2
            let textY = tileRect.midY - textSize.height / 2
            
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            // Draw text shadow
            context.saveGState()
            context.setShadow(offset: CGSize(width: 2, height: -2), blur: 5, color: NSColor.black.withAlphaComponent(0.5).cgColor)
            attributedString.draw(at: CGPoint(x: textX, y: textY))
            context.restoreGState()
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
