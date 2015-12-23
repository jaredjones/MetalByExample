//
//  MBEMetalView.swift
//  MetalByExample
//
//  Created by Jared Jones on 12/19/15.
//  Copyright © 2015 Jared Jones. All rights reserved.
//

import UIKit
import MetalKit

protocol MBEMetalViewDelegate {
    func drawInView(view: MBEMetalView)
}

class MBEMetalView: UIView {
    
    var renderer: MBERenderer!
    var delegate: MBEMetalViewDelegate!
    
    var preferredFPS: Int!
    var frameDuration: NSTimeInterval!
    var device: MTLDevice!
    var currentDrawable: CAMetalDrawable!
    var clearColor: MTLClearColor!
    var displayLink:CADisplayLink?
    var depthTexture:MTLTexture?
    var metalLayer : CAMetalLayer {
        get {
            return self.layer as! CAMetalLayer
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override class func layerClass() -> AnyClass {
        return CAMetalLayer.classForCoder()
    }
    
    func commonInit() {
        device = MTLCreateSystemDefaultDevice()
        renderer = MBERenderer(device: device)
        self.delegate = renderer
        
        preferredFPS = 60
        clearColor = MTLClearColorMake(93.0/255.0, 161.0/255.0, 219.0/255.0, 1.0)
        self.metalLayer.pixelFormat = .BGRA8Unorm
    }
    
    override var frame : CGRect {
        didSet {
            var scale = UIScreen.mainScreen().scale
            if (self.window != nil) {
                scale = (self.window?.screen.scale)!
            }
            
            var drawableSize: CGSize = self.bounds.size
            
            drawableSize.width *= scale
            drawableSize.height *= scale
            
            self.metalLayer.drawableSize = drawableSize
            
            self.makeDepthTexture()
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        let idealFramDuration: NSTimeInterval = 1.0 / 60
        let targetFrameDuration: NSTimeInterval = 1.0 / Double(self.preferredFPS)
        let frameInterval: Int = Int(round(targetFrameDuration / idealFramDuration))
        
        if (self.superview != nil) {
            self.displayLink = CADisplayLink(target: self, selector: Selector("displayLinkDidFire:"))
            self.displayLink?.frameInterval = frameInterval
            self.displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        }else {
            self.displayLink?.invalidate()
            self.displayLink = nil
        }
    }
    
    func setColorPixelFormat(colorPixelFormat: MTLPixelFormat) {
        self.metalLayer.pixelFormat = colorPixelFormat
    }
    
    func colorPixelFormat() -> MTLPixelFormat {
        return self.metalLayer.pixelFormat
    }
    
    func displayLinkDidFire(displayLink: CADisplayLink) {
        self.currentDrawable = self.metalLayer.nextDrawable()
        self.frameDuration = displayLink.duration
        
        self.delegate.drawInView(self)
    }
    
    func makeDepthTexture() {
        let drawableSize: CGSize = self.metalLayer.drawableSize
        
        if self.depthTexture?.width != Int(drawableSize.width) ||
            self.depthTexture?.height != Int(drawableSize.height) {
                let desc: MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(
                    .Depth32Float,
                    width: Int(drawableSize.width),
                    height: Int(drawableSize.height),
                    mipmapped: false)
                self.depthTexture = self.metalLayer.device?.newTextureWithDescriptor(desc)
        }
        
    }
}