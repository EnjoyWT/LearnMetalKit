//
//  Day1.swift
//  LearnMetalKit
//  Created by JoyTim on 2024/5/21
//  Copyright © 2024 ___ORGANIZATIONNAME___. All rights reserved.
//

import MetalKit
import UIKit
class Day1: BaseViewController {
    var colorChannels: [Double] = [1.0, 0.0, 0.0, 1.0] // 初始为红色
    var primaryChannel: Int = 0 // 初始主要通道为红色 (索引 0)
    var growing: Bool = true // 用于决定颜色通道是增长还是减少
    let DynamicColorRate: Double = 0.01 // 动态颜色变化速率

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func draw(in view: MTKView) {
        let color = makeFancyColor()
        view.clearColor = MTLClearColorMake(color.red, color.green, color.blue, color.alpha)
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            debugPrint("Make CommandBuffe failed!")
            return
        }

        commandBuffer.label = "MyCommand"
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
            debugPrint("Get current render pass descriptor failed!")
            return
        }
        // 通过渲染描述符renderPassDescriptor创建MTLRenderCommandEncoder 对象
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

    func makeFancyColor() -> Color {
        if growing {
            // 动态信道索引 (1,2,3,0)通道间切换
            let dynamicChannelIndex = (primaryChannel + 1) % 3
            colorChannels[dynamicChannelIndex] += DynamicColorRate
            if colorChannels[dynamicChannelIndex] >= 1.0 {
                growing = false
                // 将颜色通道修改为动态颜色通道
                primaryChannel = dynamicChannelIndex
            }
        } else {
            // 获取动态颜色通道
            let dynamicChannelIndex = (primaryChannel + 2) % 3
            colorChannels[dynamicChannelIndex] -= DynamicColorRate
            if colorChannels[dynamicChannelIndex] <= 0.0 {
                growing = true
            }
        }

        return Color(red: colorChannels[0], green: colorChannels[1], blue: colorChannels[2], alpha: colorChannels[3])
    }
}
