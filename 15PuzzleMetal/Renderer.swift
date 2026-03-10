//
//  Renderer.swift
//  15PuzzleMetal
//

import Metal
import MetalKit
import simd

let maxBuffersInFlight = 3

class Renderer: NSObject, MTKViewDelegate {

    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState
    var numberTexture: MTLTexture
    
    let puzzleLogic = PuzzleLogic()
    var projectionMatrix = matrix_float4x4()
    
    // Quad mesh for a single tile
    var vertexBuffer: MTLBuffer!
    
    struct Vertex {
        var x, y, z: Float
        var u, v: Float
    }

    @MainActor
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        self.commandQueue = self.device.makeCommandQueue()!

        metalKitView.clearColor = MTLClearColor(red: 0.15, green: 0.12, blue: 0.2, alpha: 1.0) // Matches texture background

        // Build Pipeline State
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        let mtlVertexDescriptor = MTLVertexDescriptor()
        // Position: float3 (offset 0)
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].format = .float3
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttribute.position.rawValue].bufferIndex = 0
        
        // TexCoord: float2 (offset 12)
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].format = .float2
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].offset = 12
        mtlVertexDescriptor.attributes[VertexAttribute.texcoord.rawValue].bufferIndex = 0
        
        // Stride: 12 (pos) + 8 (uv) = 20
        mtlVertexDescriptor.layouts[0].stride = 20
        mtlVertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        
        // --- Enable Alpha Blending ---
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
            return nil
        }

        // Generate Texture with Mipmapping
        guard let tex = NumberTextureGenerator.generate(device: device) else {
            return nil
        }
        
        // Re-create texture with mipmaps if we want to use generateMipmaps
        let texDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: tex.pixelFormat, width: tex.width, height: tex.height, mipmapped: true)
        texDesc.usage = [.shaderRead, .renderTarget] // renderTarget required for generateMipmaps
        guard let mipTex = device.makeTexture(descriptor: texDesc) else { return nil }
        
        // Copy initial data to level 0
        let region = MTLRegionMake2D(0, 0, tex.width, tex.height)
        let bytesPerRow = tex.width * 4
        let tempBuffer = device.makeBuffer(length: tex.width * tex.height * 4, options: .storageModeShared)!
        tex.getBytes(tempBuffer.contents(), bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        mipTex.replace(region: region, mipmapLevel: 0, withBytes: tempBuffer.contents(), bytesPerRow: bytesPerRow)
        
        // Generate Mipmaps
        if let commandBuffer = self.commandQueue.makeCommandBuffer(),
           let blitEncoder = commandBuffer.makeBlitCommandEncoder() {
            blitEncoder.generateMipmaps(for: mipTex)
            blitEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
        
        numberTexture = mipTex

        super.init()

        // Build Quad Mesh (two triangles to form a rectangle)
        // 1 - 2
        // | \ |
        // 0 - 3
        let vertices = [
            Vertex(x: -0.5, y: -0.5, z: 0, u: 0, v: 1), // 0: Bottom-Left
            Vertex(x: -0.5, y:  0.5, z: 0, u: 0, v: 0), // 1: Top-Left
            Vertex(x:  0.5, y:  0.5, z: 0, u: 1, v: 0), // 2: Top-Right
            
            Vertex(x: -0.5, y: -0.5, z: 0, u: 0, v: 1), // 0: Bottom-Left
            Vertex(x:  0.5, y:  0.5, z: 0, u: 1, v: 0), // 2: Top-Right
            Vertex(x:  0.5, y: -0.5, z: 0, u: 1, v: 1)  // 3: Bottom-Right
        ]
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * 20, options: [])
    }

    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(numberTexture, index: 0)
        
        // Global Uniforms
        var globalUniforms = GlobalUniforms(projectionMatrix: projectionMatrix)
        renderEncoder.setVertexBytes(&globalUniforms, length: MemoryLayout<GlobalUniforms>.size, index: 2)
        
        // Draw 16 tiles (skipping the empty space)
        let tileSize: Float = 1.0
        let spacing: Float = 0.05
        let totalSize = Float(puzzleLogic.size) * tileSize + Float(puzzleLogic.size - 1) * spacing
        let startOffset = -totalSize / 2 + tileSize / 2
        
        for i in 0..<16 {
            let number = puzzleLogic.board[i]
            if number == 0 { continue } // Skip blank tile
            
            let row = i / 4
            let col = i % 4
            
            let x = startOffset + Float(col) * (tileSize + spacing)
            let y = -startOffset - Float(row) * (tileSize + spacing)
            
            let modelMatrix = matrix4x4_translation(x, y, 0)
            
            // UV mapping: tile 'number' is at its original position in the texture
            // The number 1 is at index 0 (row 0, col 0) in the texture
            let originalIndex = number - 1
            let texRow = originalIndex / 4
            let texCol = originalIndex % 4
            
            let uvOffset = simd_float2(Float(texCol) / 4.0, Float(texRow) / 4.0)
            let uvScale = simd_float2(0.25, 0.25)
            
            var tileUniforms = TileUniforms(modelMatrix: modelMatrix,
                                            uvOffset: uvOffset,
                                            uvScale: uvScale)
            
            renderEncoder.setVertexBytes(&tileUniforms, length: MemoryLayout<TileUniforms>.size, index: 3)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
        
        renderEncoder.endEncoding()
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let aspect = Float(size.width) / Float(size.height)
        let zoom: Float = 5.0
        projectionMatrix = matrix_ortho_right_hand(left: -aspect * zoom, right: aspect * zoom, bottom: -zoom, top: zoom, nearZ: -1, farZ: 1)
    }
}

func matrix4x4_translation(_ tx: Float, _ ty: Float, _ tz: Float) -> matrix_float4x4 {
    return matrix_float4x4(columns: (
        vector_float4(1, 0, 0, 0),
        vector_float4(0, 1, 0, 0),
        vector_float4(0, 0, 1, 0),
        vector_float4(tx, ty, tz, 1)
    ))
}

func matrix_ortho_right_hand(left: Float, right: Float, bottom: Float, top: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let xs = 2 / (right - left)
    let ys = 2 / (top - bottom)
    let zs = 1 / (nearZ - farZ)
    return matrix_float4x4(columns: (
        vector_float4(xs, 0, 0, 0),
        vector_float4(0, ys, 0, 0),
        vector_float4(0, 0, zs, 0),
        vector_float4((left + right) / (left - right), (top + bottom) / (bottom - top), nearZ / (nearZ - farZ), 1)
    ))
}
