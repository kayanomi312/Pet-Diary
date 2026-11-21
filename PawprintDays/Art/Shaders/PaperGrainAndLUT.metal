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
    float grain = (paperHash(floor(pos * 0.75)) - 0.5) * 0.055; // 5.5% cold-press tooth
    half3 rgb = color.rgb + half3(grain);
    if (weatherMode > 0.5 && weatherMode < 1.5) {
        rgb = mix(rgb, rgb * half3(0.93h, 0.97h, 1.04h), 0.35h); // Rain
    } else if (weatherMode >= 1.5) {
        rgb = mix(rgb, rgb * half3(1.06h, 0.98h, 0.88h), 0.40h); // Dusk / Lamp
    }
    return half4(clamp(rgb, 0.0h, 1.0h), color.a);
}
