//
//  Day5.metal
//  LearnMetalKit
//  Created by JoyTim on 2024/5/30
//  Copyright © 2024 ___ORGANIZATIONNAME___. All rights reserved.
//
    

#include <metal_stdlib>
#import "LYShaderTypes.h"

using namespace metal;

typedef struct
{
    float4 clipSpacePosition [[position]]; // position的修饰符表示这个是顶点
    
    float2 textureCoordinate; // 纹理坐标，会做插值处理
    
} RasterizerData;

vertex RasterizerData // 返回给片元着色器的结构体
day5VertexShader(uint vertexID [[ vertex_id ]], // vertex_id是顶点shader每次处理的index，用于定位当前的顶点
             constant LYVertex *vertexArray [[ buffer(0) ]]) { // buffer表明是缓存数据，0是索引
    RasterizerData out;
    out.clipSpacePosition = vertexArray[vertexID].position;
    out.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    return out;
}

fragment float4
day5SamplingShader(RasterizerData input [[stage_in]], // stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
               texture2d<half> colorTexture [[ texture(0) ]],texture2d<half> colorTexture1 [[ texture(1) ]]) // texture表明是纹理数据，0是索引
{
    constexpr sampler textureSampler (mag_filter::linear,
                                      min_filter::linear); // sampler是采样器
    

    half4 colorSample = colorTexture.sample(textureSampler, input.textureCoordinate);
    

    half4 colorSample1 = colorTexture1.sample(textureSampler, input.textureCoordinate);

    return float4(colorSample);
    
    // 如果第二个纹理的alpha值大于0，则使用第二个纹理的颜色，否则使用第一个纹理的颜色
//    return colorSample1.a > 0.0 ? float4(colorSample1) : float4(colorSample);

}




