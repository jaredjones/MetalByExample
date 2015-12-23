//
//  MBERenderer.swift
//  MetalByExample
//
//  Created by Jared Jones on 12/23/15.
//  Copyright © 2015 Jared Jones. All rights reserved.
//

import Foundation
import MetalKit

typealias MBEIndex = UInt16
let MBEIndexType:MTLIndexType = MTLIndexType.UInt16

struct MBEVertex {
    var position:float4
    var color:float4
}

struct MBEUniforms {
    var MVP: matrix_float4x4
}

class MBERenderer: MBEMetalViewDelegate {
    
    let kInFlightCommandBuffers = 3
    let inflightSemaphore:dispatch_semaphore_t
    var bufferIndex = 0
    
    var device: MTLDevice
    var commandQueue:MTLCommandQueue?
    var pipeline:MTLRenderPipelineState?
    var depthStencilState:MTLDepthStencilState?
    
    var vertexBuffer:MTLBuffer?
    var indexBuffer:MTLBuffer?
    var uniformBuffer:MTLBuffer?
    
    init(device: MTLDevice) {
        self.device = device
        inflightSemaphore = dispatch_semaphore_create(kInFlightCommandBuffers)
        makePipeline()
        makeBuffers()
    }
    
    func makePipeline() {
        let library = self.device.newDefaultLibrary()
        let vertexFunc = library?.newFunctionWithName("vertex_main")
        let fragmentFunc = library?.newFunctionWithName("fragment_main")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .Depth32Float
        pipelineDescriptor.vertexFunction = vertexFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .Less
        depthStencilDescriptor.depthWriteEnabled = true
        
        self.depthStencilState = self.device.newDepthStencilStateWithDescriptor(depthStencilDescriptor)
        
        do {
            try self.pipeline = self.device.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
        } catch MTLRenderPipelineError.InvalidInput{
            print("The input values are invalid")
        } catch MTLRenderPipelineError.Internal {
            print("This action caused an internal error")
        } catch MTLRenderPipelineError.Unsupported {
            print("This action is unsupported")
        } catch {
            print("Unknown RenderPipelineState Error")
        }
        
        self.commandQueue = self.device.newCommandQueue()
    }
    
    func makeBuffers() {
        let vertices:[MBEVertex] = [
            MBEVertex(position: [-1,  1,  1, 1], color: [0, 1, 1, 1]),
            MBEVertex(position: [-1, -1,  1, 1], color: [0, 0, 1, 1]),
            MBEVertex(position: [ 1, -1,  1, 1], color: [1, 0, 1, 1]),
            MBEVertex(position: [ 1,  1,  1, 1], color: [1, 1, 1, 1]),
            MBEVertex(position: [-1,  1, -1, 1], color: [0, 1, 0, 1]),
            MBEVertex(position: [-1, -1, -1, 1], color: [0, 0, 0, 1]),
            MBEVertex(position: [ 1, -1, -1, 1], color: [1, 0, 0, 1]),
            MBEVertex(position: [ 1,  1, -1, 1], color: [1, 1, 0, 1])
        ]
        
        let indicies: [MBEIndex] = [
            3,2,6,6,7,3,
            4,5,1,1,0,4,
            4,0,3,3,7,4,
            1,5,6,6,2,1,
            0,1,2,2,3,0,
            7,6,5,5,4,7
        ]
        
        let vertexSize = vertices.count * sizeofValue(vertices[0])
        let indexSize = indicies.count * sizeofValue(indicies[0])
        self.vertexBuffer = self.device.newBufferWithBytes(vertices, length: vertexSize, options: .CPUCacheModeDefaultCache)
        self.indexBuffer = self.device.newBufferWithBytes(indicies, length: indexSize, options: .CPUCacheModeDefaultCache)
        self.uniformBuffer = self.device.newBufferWithLength(sizeof(MBEUniforms) * kInFlightCommandBuffers, options: .CPUCacheModeDefaultCache)
    }
    
    var rotDeg: Double = 0.0
    
    func updateUniforms(view: MBEMetalView, duration:NSTimeInterval) {
        var viewMatrix:matrix_float4x4
        var projMatrix:matrix_float4x4
        var modelMatrix:matrix_float4x4
        
        viewMatrix = matrix_float4x4_identity()
        
        let cameraTranslation: float3 = [0, 0, -7]
        viewMatrix = matrix_multiply(viewMatrix, matrix_float4x4_translation(cameraTranslation))
        
        let near:Float = 0.1
        let far:Float = 100.0
        let aspect:Float = Float(view.metalLayer.drawableSize.width / view.metalLayer.drawableSize.height)
        let fov:Float = Float((2 * M_PI) / 5)
        projMatrix = matrix_float4x4_perspective(aspect, fovy: fov, near: near, far: far)
        
        modelMatrix = matrix_float4x4_identity()
        modelMatrix = matrix_multiply(modelMatrix, matrix_float4x4_rotation(float3(1, 0, 0), angle: Float(rotDeg)))
        
        rotDeg += duration
        
        let MVP = matrix_multiply(projMatrix, matrix_multiply(viewMatrix, modelMatrix))
        var uniforms: MBEUniforms = MBEUniforms(MVP: MVP)
        
        let uniformBufferOffset = sizeof(MBEUniforms) * self.bufferIndex
        memcpy((uniformBuffer?.contents())! + uniformBufferOffset, &uniforms, sizeofValue(uniforms))
    }

    
    func drawInView(view: MBEMetalView) {
        dispatch_semaphore_wait(inflightSemaphore, DISPATCH_TIME_FOREVER)
        
        updateUniforms(view, duration: view.frameDuration)
        
        // MTLTextures are containers for images, where each image is called a slice.
        // each texture has a particular size and pixel format. 1D/2D/3D
        
        // We are using a single 2D texture for our renderbuffer (same resolution as screen)
        // CAMetalDrawable will give us a nextDrawable from the CALayer that has a texture we
        // may use as our screen buffer
        let drawable: CAMetalDrawable = view.currentDrawable
        let texture:MTLTexture = drawable.texture
        
        // A pass descriptor tells Metal which actions to take while a frame is being rendered
        // The LoadAction tells us whether the previous contents are Cleared or Retained
        // The StoreAction deals with the effects the rendering has on our texture, to store or discard
        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = texture
        passDescriptor.colorAttachments[0].loadAction = .Clear
        passDescriptor.colorAttachments[0].storeAction = .Store
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(93.0/255.0, 161.0/255.0, 219.0/255.0, 1.0)
        
        passDescriptor.depthAttachment.texture = view.depthTexture
        passDescriptor.depthAttachment.clearDepth = 1.0
        passDescriptor.depthAttachment.loadAction = .Clear
        passDescriptor.depthAttachment.storeAction = .DontCare
        
        // The CommandQueue is given to us by the device and holds a list of CommandBuffers.
        // Generally the CommandQueue exists for more than one frame
        
        // The CommandBuffer is a collection of render commands to be executed together as a single unit
        
        // The CommandEncoder tells Metal what drawing we want to do. It translates high level code like
        // (Set Shaders, Draw Triangles, etc) and converts them to lower level instructions that are written
        // into the CommandBuffer. After we finish our draw calls, we send endEncoding to the CommandEncoder so
        // it has a chance to finish its encoding.
        
        let commandBuffer = commandQueue?.commandBuffer()
        
        let commandEncoder = commandBuffer?.renderCommandEncoderWithDescriptor(passDescriptor)
        commandEncoder?.setRenderPipelineState(self.pipeline!)
        commandEncoder?.setDepthStencilState(self.depthStencilState!)
        commandEncoder?.setFrontFacingWinding(.CounterClockwise)
        commandEncoder?.setCullMode(.Back)
        
        commandEncoder?.setVertexBuffer(self.vertexBuffer, offset: 0, atIndex: 0) //Index 0 matches buffer(0) in Shader
        commandEncoder?.setVertexBuffer(self.uniformBuffer, offset: 0, atIndex: 1)
        
        //commandEncoder?.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3)
        commandEncoder?.drawIndexedPrimitives(.Triangle,
            indexCount: (self.indexBuffer?.length)! / sizeof(MBEIndex),
            indexType: MBEIndexType,
            indexBuffer: self.indexBuffer!,
            indexBufferOffset: 0)
        
        commandEncoder?.endEncoding()
        
        // Presents a drawable object when the command buffer is executed.
        commandBuffer!.presentDrawable(drawable)
        
        commandBuffer!.addCompletedHandler { (buffer:MTLCommandBuffer) -> Void in
            self.bufferIndex = (self.bufferIndex + 1) % self.kInFlightCommandBuffers
            dispatch_semaphore_signal(self.inflightSemaphore)
        }
        
        // The CommandBuffer is executed by the GPU.
        commandBuffer!.commit()
    }
}