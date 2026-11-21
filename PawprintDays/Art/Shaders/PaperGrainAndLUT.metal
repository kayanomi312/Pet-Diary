#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

float paperHash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

[[ stitchable ]] half4 paperGrainAndWeather(float2 pos, half4 color, float weatherMode) {
    if (color.a <= 0.001h) return color;
    float fineGrain = (paperHash(floor(pos * 0.75)) - 0.5) * 0.052;
    float fiber = (paperHash(floor(float2(pos.x * 0.18, pos.y * 0.65))) - 0.5) * 0.022;
    half3 rgb = color.rgb + half3(fineGrain + fiber);
    if (weatherMode > 0.5 && weatherMode < 1.5) {
        rgb = mix(rgb, rgb * half3(0.92h, 0.97h, 1.05h), 0.36h); // Rain mist
    } else if (weatherMode >= 1.5) {
        rgb = mix(rgb, rgb * half3(1.07h, 0.98h, 0.87h), 0.42h); // Golden dusk / lamp
    }
    return half4(clamp(rgb, 0.0h, 1.0h), color.a);
}

[[ stitchable ]] half4 storybookPaperSurface(float2 pos, half4 color) {
    if (color.a <= 0.001h) return color;
    float tooth = (paperHash(floor(pos * 0.85)) - 0.5) * 0.040;
    float weaveH = (paperHash(floor(float2(pos.x * 0.12, pos.y * 0.80))) - 0.5) * 0.018;
    float weaveV = (paperHash(floor(float2(pos.x * 0.80, pos.y * 0.12))) - 0.5) * 0.014;
    half3 rgb = color.rgb + half3(tooth + weaveH + weaveV);
    return half4(clamp(rgb, 0.0h, 1.0h), color.a);
}
