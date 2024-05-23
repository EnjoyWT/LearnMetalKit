//
//  BaseViewController.swift
//  LearnMetalKit
//  Created by JoyTim on 2024/5/21
//  Copyright © 2024 ___ORGANIZATIONNAME___. All rights reserved.
//
    

import Foundation
import MetalKit
import UIKit

class BaseViewController: UIViewController {
    var metalView: MTKView!
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
  
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 创建 Metal 设备
        device = MTLCreateSystemDefaultDevice()

        // 创建 MTKView
        metalView = MTKView(frame: CGRect(x: 100, y: 150, width: 200, height: 100), device: device)

//        metalView = MTKView(frame: view.bounds, device: device)
//        metalView.enableSetNeedsDisplay = true // 是否实时绘制

        metalView.clearColor = MTLClearColor(red: 1, green: 0.0, blue: 0.0, alpha: 1.0)
        metalView.delegate = self
        view.addSubview(metalView)

        // 创建命令队列
        commandQueue = device.makeCommandQueue()

    }


}
struct Color {
    let red, green, blue, alpha : Double
}
extension BaseViewController: MTKViewDelegate {
    func draw(in view: MTKView) {

        guard let commandBuffer = self.commandQueue?.makeCommandBuffer() else {
            debugPrint("Make CommandBuffe failed!")
            return
        }
        
        commandBuffer.label = "MyCommand"
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            debugPrint("Get current render pass descriptor failed!")
            return
        }
        //通过渲染描述符renderPassDescriptor创建MTLRenderCommandEncoder 对象
        guard let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            debugPrint("Make render command encoder failed!")
            return
        }
        renderCommandEncoder.label = "MyRenderCommandEncoder"
        renderCommandEncoder.endEncoding()
        
        guard let drawable = view.currentDrawable else {
            debugPrint("Get current drawable failed!")
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

}
