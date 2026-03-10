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
        var position: SIMD3<Float>
        var texCoord: SIMD2<Float>
    }

    @MainActor
    init?(metalKitView: MTKView) {
        self.device = metalKitView.device!
        self.commandQueue = self.device.makeCommandQueue()!

        metalKitView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        metalKitView.colorPixelFormat = .bgra8Unorm_srgb

        // Build Pipeline State
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        let mtlVertexDescriptor = MTLVertexDescriptor()
        mtlVertexDescriptor.attributes[0].format = .float3
        mtlVertexDescriptor.attributes[0].offset = 0
        mtlVertexDescriptor.attributes[0].bufferIndex = 0
        mtlVertexDescriptor.attributes[1].format = .float2
        mtlVertexDescriptor.attributes[1].offset = 12
        mtlVertexDescriptor.attributes[1].bufferIndex = 0
        mtlVertexDescriptor.layouts[0].stride = 20
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Failed to create pipeline state: \(error)")
            return nil
        }

        // Generate Texture
        guard let tex = NumberTextureGenerator.generate(device: device) else {
            return nil
        }
        numberTexture = tex

        super.init()

        // Build Quad Mesh
        let vertices = [
            Vertex(position: [-0.5, -0.5, 0], texCoord: [0, 1]),
            Vertex(position: [ 0.5, -0.5, 0], texCoord: [1, 1]),
            Vertex(position: [-0.5,  0.5, 0], texCoord: [0, 0]),
            
            Vertex(position: [ 0.5, -0.5, 0], texCoord: [1, 1]),
            Vertex(position: [ 0.5,  0.5, 0], texCoord: [1, 0]),
            Vertex(position: [-0.5,  0.5, 0], texCoord: [0, 0])
        ]
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Vertex>.stride, options: [])
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
