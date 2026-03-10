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
        
        // Fill background (clear or black)
        context.setFillColor(NSColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Divide into 4x4 grid (16 tiles)
        let tileSize = width / 4
        
        for i in 0..<16 {
            let number = i + 1
            if number > 15 { continue } // 16th is empty
            
            let row = i / 4
            let col = i % 4
            
            // Draw tile background
            let rect = CGRect(x: col * tileSize, y: (3 - row) * tileSize, width: tileSize, height: tileSize)
            context.setFillColor(NSColor.darkGray.cgColor)
            context.setStrokeColor(NSColor.white.cgColor)
            context.setLineWidth(2.0)
            context.fill(rect.insetBy(dx: 2, dy: 2))
            context.stroke(rect.insetBy(dx: 2, dy: 2))
            
            // Draw number
            let text = "\(number)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: CGFloat(tileSize) * 0.6),
                .foregroundColor: NSColor.white
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedString.size()
            
            let textX = rect.midX - textSize.width / 2
            let textY = rect.midY - textSize.height / 2
            
            // CoreGraphics coordinate system: origin at bottom-left
            // Flip text rendering if needed, but since we are drawing to CGContext, it should be fine.
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
