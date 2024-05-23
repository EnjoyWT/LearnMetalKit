//
//  Day3.swift
//  LearnMetalKit
//  Created by JoyTim on 2024/5/23
//  Copyright © 2024 ___ORGANIZATIONNAME___. All rights reserved.
//

import MetalKit
import simd
import UIKit
/**
  显示图片,并且实现imageview 渲染图片时的裁剪方式.
 目前顶点坐标直接使用的NDC坐标没有做任何处理. 坐标部分理解不太透彻.对于显示图片来说可以按照目前方法使用
 TODO:
 1. 频繁切换图片时,资源竞争问题
 */
enum ContentMode {
    case scaleAspectFit
    case scaleAspectFill
    case scaleToFill
}

class Day3: BaseViewController {
    var piplineState: MTLRenderPipelineState!
    var viewPortSize: vector_uint2?

    var triangleVertices: [LYVertex]!
    var verticesSize: Int!
    var texture: MTLTexture!
    override func viewDidLoad() {
        super.viewDidLoad()

        metalView.frame = CGRect(x: 100, y: 150, width: 200, height: 100)
        view.backgroundColor = .green
        pipeline()
        vertices()
        setupTexture()

     
        viewPortSize = vector_uint2(UInt32(metalView.drawableSize.width), UInt32(metalView.drawableSize.height))
    }

    func pipeline() {
        // Do any additional setup after loading the view.
        let dl = device.makeDefaultLibrary()
        let vertexShader = dl?.makeFunction(name: "day3VertexShader")
        let fragmentShader = dl?.makeFunction(name: "day3SamplingShader")
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
        // 渲染图片和当前的窗口大小一致, 图片纹理坐标y轴是颠倒的(仅指当前的数据和NDC布局数值颠倒).
        triangleVertices = [
            LYVertex(position: vector_float4(1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0)),
            LYVertex(position: vector_float4(-1, -1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 1.0)),
            LYVertex(position: vector_float4(-1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0)),
            LYVertex(position: vector_float4(1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0)),
            LYVertex(position: vector_float4(-1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0)),
            LYVertex(position: vector_float4(1, 1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 0.0))
        ]

//        let t = [
//            LYVertex(position: vector_float4(1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0)),
//            LYVertex(position: vector_float4(-1, -1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 1.0)),
//            LYVertex(position: vector_float4(-1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0)),
//            LYVertex(position: vector_float4(1, -1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 1.0)),
//            LYVertex(position: vector_float4(-1, 1, 0.0, 1.0), textureCoordinate: vector_float2(0.0, 0.0)),
//            LYVertex(position: vector_float4(1, 1, 0.0, 1.0), textureCoordinate: vector_float2(1.0, 0.0))
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
        guard let image = UIImage(named: "abc") else { return }

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
        //这里偷懒了.进行了二次处理,因为不知道图片的大小.
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
