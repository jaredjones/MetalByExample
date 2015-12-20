//
//  MBEMetalView.swift
//  MetalByExample
//
//  Created by Jared Jones on 12/19/15.
//  Copyright © 2015 Jared Jones. All rights reserved.
//

import UIKit
import MetalKit

class MBEMetalView: UIView {

    private(set) var metalLayer:CAMetalLayer!
    private(set) var device:MTLDevice!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.metalLayer = self.layer as! CAMetalLayer
        self.device = MTLCreateSystemDefaultDevice()
        self.metalLayer.device = self.device
        self.metalLayer.pixelFormat = .BGRA8Unorm
    }
    
    override class func layerClass() -> AnyClass {
        return CAMetalLayer.classForCoder()
    }
    
    override func didMoveToWindow() {
        self.redraw()
    }
    
    func redraw () {
        // MTLTextures are containers for images, where each image is called a slice.
        // each texture has a particular size and pixel format. 1D/2D/3D
        
        // We are using a single 2D texture for our renderbuffer (same resolution as screen)
        // CAMetalDrawable will give us a nextDrawable from the CALayer that has a texture we
        // may use as our screen buffer
        let drawable: CAMetalDrawable = self.metalLayer.nextDrawable()!
        let texture:MTLTexture = drawable.texture
        
        // A pass descriptor tells Metal which actions to take while a frame is being rendered
        // The LoadAction tells us whether the previous contents are Cleared or Retained
        // The StoreAction deals with the effects the rendering has on our texture, to store or discard
        let passDescriptor = MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = texture
        passDescriptor.colorAttachments[0].loadAction = .Clear
        passDescriptor.colorAttachments[0].storeAction = .Store
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 0.0, 1.0)
        
        // The CommandQueue is given to us by the device and holds a list of CommandBuffers.
        // Generally the CommandQueue exists for more than one frame
        
        // The CommandBuffer is a collection of render commands to be executed together as a single unit
        
        // The CommandEncoder tells Metal what drawing we want to do. It translates high level code like 
        // (Set Shaders, Draw Triangles, etc) and converts them to lower level instructions that are written
        // into the CommandBuffer. After we finish our draw calls, we send endEncoding to the CommandEncoder so
        // it has a chance to finish its encoding.
        
        let commandQueue = self.device.newCommandQueue()
        let commandBuffer = commandQueue.commandBuffer()
        let commandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(passDescriptor)
        commandEncoder.endEncoding()
        
        
        // Presents a drawable object when the command buffer is executed.
        commandBuffer.presentDrawable(drawable)
        // The CommandBuffer is executed by the GPU.
        commandBuffer.commit()
    }
}
