//
//  Day4.swift
//  LearnMetalKit
//  Created by JoyTim on 2024/5/24
//  Copyright © 2024 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation

import MetalKit
import simd
import UIKit
/*
 替换背景: 使用mask 直接抠图替换背景
 */
class Day4: BaseViewController {
    var piplineState: MTLRenderPipelineState!
    var viewPortSize: vector_uint2?

    var triangleVertices: [LYVertex]!
    var verticesSize: Int!
    var texture: MTLTexture!

    var texture1: MTLTexture!
    var texture2: MTLTexture!

    var btn: UIButton!

    var isShowBg: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()

        metalView.frame = CGRect(x: 100, y: 150, width: 200, height: 300)
        view.backgroundColor = .green
        pipeline()
        vertices()
        setupTexture()

        viewPortSize = vector_uint2(UInt32(metalView.drawableSize.width), UInt32(metalView.drawableSize.height))

        btn = UIButton(type: .custom)
        btn.frame = CGRect(x: 100, y: 500, width: 80, height: 40)

        view.addSubview(btn)
        btn.addTarget(self, action: #selector(btnClick(_:)), for: .touchUpInside)
        btn.setTitle("换背景", for: .normal)
        btn.backgroundColor = .blue
    }

    @objc func btnClick(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        isShowBg = !isShowBg
    }

    func pipeline() {
        // Do any additional setup after loading the view.
        let dl = device.makeDefaultLibrary()
        let vertexShader = dl?.makeFunction(name: "day4VertexShader")
        let fragmentShader = dl?.makeFunction(name: "day4SamplingShader")
        let rpd = MTLRenderPipelineDescriptor()
        rpd.label = "my pip"
        rpd.vertexFunction = vertexShader
        rpd.fragmentFunction = fragmentShader
        rpd.colorAttachments[0].pixelFormat = metalView.colorPixelFormat

        do {
            piplineState = try device.makeRenderPipelineState(descriptor: rpd)

        } catch {
            print(error.localizedDescription)
        }
    }

    func vertices() {
        /* 渲染图片和当前的窗口大小一致,这个和OpenGl中图片纹理坐标不一样
          https://juejin.cn/post/6844904040191492104
         在 iOS 中，图片纹理坐标系统的原点(0, 0)位于左上角。

         X 轴的正方向是从左到右。
         Y 轴的正方向是从上到下。

         这与 Core Graphics 和 UIKit 中使用的坐标系统相同。
         也就是说，纹理坐标系统中:

         (0, 0) 表示左上角
         (1, 0) 表示右上角
         (0, 1) 表示左下角
         (1, 1) 表示右下角 */
        triangleVertices = [
            LYVertex(position: vector_float4(1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0)),
            LYVertex(position: vector_float4(-1, -1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 1.0)),
            LYVertex(position: vector_float4(-1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0)),

            LYVertex(position: vector_float4(1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0)),
            LYVertex(position: vector_float4(-1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0)),
            LYVertex(position: vector_float4(1, 1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 0.0))
        ]
        // 旋转像屏幕向翻转180
//        triangleVertices = [
//            LYVertex(position: vector_float4(1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 0.0)),
//            LYVertex(position: vector_float4(-1, -1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0)),
//            LYVertex(position: vector_float4(-1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 1.0)),
//
//            LYVertex(position: vector_float4(1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 0.0)),
//            LYVertex(position: vector_float4(-1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 1.0)),
//            LYVertex(position: vector_float4(1, 1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0))
//        ]
        // 顺指针旋转 90 ,和opengl中有向图纹理 保持一致
//        triangleVertices = [
//            LYVertex(position: vector_float4(1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 0.0)),
//            LYVertex(position: vector_float4(-1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0)),
//            LYVertex(position: vector_float4(-1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 1.0)),
//
//            LYVertex(position: vector_float4(1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 0.0)),
//            LYVertex(position: vector_float4(-1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 1.0)),
//            LYVertex(position: vector_float4(1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0))
//        ]

        verticesSize = triangleVertices.count * MemoryLayout<LYVertex>.stride
    }

    func calculateVertices(for contentMode: ContentMode, textureSize: CGSize, viewSize: CGSize) -> [LYVertex] {
        let textureAspect = textureSize.width / textureSize.height
        let viewAspect = viewSize.width / viewSize.height

        var scaleX: Float = 1.0
        var scaleY: Float = 1.0

        switch contentMode {
        case .scaleAspectFit:
            if viewAspect > textureAspect {
                scaleX = Float(textureSize.width * viewSize.height / (textureSize.height * viewSize.width))
            } else {
                scaleY = Float(textureSize.height * viewSize.width / (textureSize.width * viewSize.height))
            }

        case .scaleAspectFill:
            if viewAspect > textureAspect {
                scaleY = Float(viewSize.width * textureSize.height / (viewSize.height * textureSize.width))
            } else {
                scaleX = Float(viewSize.height * textureSize.width / (viewSize.width * textureSize.height))
            }

        case .scaleToFill:
            break // 默认情况下 scaleX 和 scaleY 都是 1.0
        }

        let vertices = [
            LYVertex(position: vector_float4(1 * scaleX, -1 * scaleY, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0)),
            LYVertex(position: vector_float4(-1 * scaleX, -1 * scaleY, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 1.0)),
            LYVertex(position: vector_float4(-1 * scaleX, 1 * scaleY, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0)),
            LYVertex(position: vector_float4(1 * scaleX, -1 * scaleY, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0)),
            LYVertex(position: vector_float4(-1 * scaleX, 1 * scaleY, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0)),
            LYVertex(position: vector_float4(1 * scaleX, 1 * scaleY, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 0.0))
        ]

        return vertices
    }

    func setupTexture() {
        guard let image = UIImage(named: "bgreen1.jpg") else { return }

        guard let originalImage = UIImage(named: "bg2.jpg"),
              let maskImage = UIImage(named: "mask1.jpg")
        else {
            fatalError("Failed to load images")
        }
        // 纹理描述符
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = .rgba8Unorm
        textureDescriptor.width = Int(image.size.width)
        textureDescriptor.height = Int(image.size.height)

        texture = device.makeTexture(descriptor: textureDescriptor) // 创建纹理

        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: Int(image.size.width), height: Int(image.size.height), depth: 1)) // 纹理上传的范围

        if let imageBytes = loadImage(image) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
            texture?.replace(region: region, mipmapLevel: 0, withBytes: imageBytes, bytesPerRow: 4 * Int(image.size.width))
            free(imageBytes) // 需要释放资源
        }

        // 纹理描述符
        let textureDescriptor1 = MTLTextureDescriptor()
        textureDescriptor1.pixelFormat = .rgba8Unorm
        textureDescriptor1.width = Int(originalImage.size.width)
        textureDescriptor1.height = Int(originalImage.size.height)

        texture1 = device.makeTexture(descriptor: textureDescriptor1) // 创建纹理

        let region1 = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: Int(originalImage.size.width), height: Int(originalImage.size.height), depth: 1)) // 纹理上传的范围

        if let imageBytes = loadImage(originalImage) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
            texture1?.replace(region: region1, mipmapLevel: 0, withBytes: imageBytes, bytesPerRow: 4 * Int(originalImage.size.width))
            free(imageBytes) // 需要释放资源
        }

        let textureDescriptor2 = MTLTextureDescriptor()
        textureDescriptor2.pixelFormat = .rgba8Unorm
        textureDescriptor2.width = Int(maskImage.size.width)
        textureDescriptor2.height = Int(maskImage.size.height)

        texture2 = device.makeTexture(descriptor: textureDescriptor2) // 创建纹理

        let region2 = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: Int(maskImage.size.width), height: Int(maskImage.size.height), depth: 1)) // 纹理上传的范围

        if let imageBytes = loadImage(maskImage) { // UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
            texture2?.replace(region: region2, mipmapLevel: 0, withBytes: imageBytes, bytesPerRow: 4 * Int(maskImage.size.width))
            free(imageBytes) // 需要释放资源
        }

        // 这里偷懒了.进行了二次处理,因为不知道图片的大小.
        triangleVertices = calculateVertices(for: .scaleAspectFit, textureSize: CGSize(width: Int(image.size.width), height: Int(image.size.height)), viewSize: metalView.drawableSize)
    }

    func loadImage(_ image: UIImage) -> UnsafeMutableRawPointer? {
        guard let spriteImage = image.cgImage else { return nil }

        // 2 读取图片的大小
        let width = spriteImage.width
        let height = spriteImage.height

        let bytesPerRow = width * 4 // rgba共4个byte
        let spriteData = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * height, alignment: 4)

        // 3在CGContextRef上绘图
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(data: spriteData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            free(spriteData)
            return nil
        }

        context.draw(spriteImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return spriteData
    }

    override func draw(in view: MTKView) {
        view.clearColor = MTLClearColorMake(0, 0, 0, 1)
//

        /*         绘制一个矩形通常需要定义四个顶点。然而，由于大多数图形 API（包括 Metal）只支持三角形的绘制，通常我们会将矩形分割成两个三角形来绘制。因此，绘制一个矩形实际上需要定义六个顶点，或者定义四个顶点并使用索引来定义两个三角形。
         */

        /*
         let vertexData: [Float] = [
             -1.0,  1.0, 0.0,  // 顶点1：左上角
              1.0,  1.0, 0.0,  // 顶点2：右上角
             -1.0, -1.0, 0.0,  // 顶点3：左下角

             -1.0, -1.0, 0.0,  // 顶点3：左下角
              1.0,  1.0, 0.0,  // 顶点2：右上角
              1.0, -1.0, 0.0   // 顶点4：右下角
         ]
         //或者通过索引定义,大量重复数据时可以采用
         let vertexData: [Float] = [
             -1.0,  1.0, 0.0,  // 顶点0：左上角
              1.0,  1.0, 0.0,  // 顶点1：右上角
             -1.0, -1.0, 0.0,  // 顶点2：左下角
              1.0, -1.0, 0.0   // 顶点3：右下角
         ]

         let indexData: [UInt16] = [
             0, 1, 2,  // 第一个三角形
             2, 1, 3   // 第二个三角形
         ]

         */

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
        renderCommandEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(viewPortSize!.x), height: Double(viewPortSize!.y), znear: 0.0, zfar: 1.0))

        renderCommandEncoder.setRenderPipelineState(piplineState)

        renderCommandEncoder.setVertexBytes(triangleVertices, length: verticesSize, index: 0)

        renderCommandEncoder.setFragmentTexture(texture, index: 0)
        if isShowBg {
            renderCommandEncoder.setFragmentTexture(texture1, index: 1)

            renderCommandEncoder.setFragmentTexture(texture2, index: 2)
        }

        // 创建一个 UInt8 类型的变量
        var boolValueUInt8: UInt8 = isShowBg ? 1 : 0

        let boolValueUInt8Ptr = withUnsafePointer(to: boolValueUInt8) {
            $0
        }
        // 获取 UInt8 变量的大小
        let boolValueUInt8Size = MemoryLayout<UInt8>.size

        // 设置数据到 fragment 函数
        renderCommandEncoder.setFragmentBytes(boolValueUInt8Ptr, length: boolValueUInt8Size, index: 0)

        renderCommandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: triangleVertices.count)
        renderCommandEncoder.endEncoding()

        guard let drawable = view.currentDrawable else {
            debugPrint("Get current drawable failed!")
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}
