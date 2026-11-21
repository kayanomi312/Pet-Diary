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

// MARK: - Live2D-Style Multi-Bone Free-Form Mesh Deformation (GPU 60fps)
// Independently animates Head tilt/shift, Ear twitch, Tail sinuous wag,
// Wing/Scale flutter, Alternating Front-Paw kneading/stepping, and Chest breathing
// directly on each hand-painted 1024x1024 watercolor creature illustration.
[[ stitchable ]] float2 live2DCreatureWarp(
    float2 pos,
    float2 viewSize,
    float4 headBone,      // xy = head center UV, z = head radius UV, w = head tilt radians
    float4 headShift,     // xy = head XY shift UV, z = ear twitch amp, w = chest breath amp
    float4 tailBone,      // xy = tail center UV, z = tail radius UV, w = tail wag phase
    float4 tailParams,    // x = tail wag amp, y = wing flap amp, z = wing U, w = wing V
    float4 pawBones,      // xy = left paw UV, zw = right paw UV
    float2 pawLifts       // x = left paw lift UV, y = right paw lift UV
) {
    float w = max(viewSize.x, 1.0);
    float h = max(viewSize.y, 1.0);
    float2 uv = float2(pos.x / w, pos.y / h);
    float2 sampleUV = uv;

    // 1. Ribcage / Belly localized breathing (paws stay planted)
    float2 chestCenter = float2(headBone.x + 0.06, headBone.y + 0.30);
    float2 dChest = uv - chestCenter;
    float chestWeight = exp(-dot(dChest, dChest) / 0.045);
    sampleUV -= dChest * (headShift.w * chestWeight);

    // 2. Independent Tail Sinuous S-Curve Wagging
    if (tailBone.z > 0.01 && abs(tailParams.x) > 0.0005) {
        float2 dTail = uv - tailBone.xy;
        float distTail = length(dTail);
        float tailWeight = exp(-(distTail * distTail) / (tailBone.z * tailBone.z * 0.72));
        // Travelling sine wave along tail arc for supple whip-like wagging
        float wave = sin(tailBone.w - distTail * 11.0);
        float wagShiftX = wave * tailParams.x * tailWeight;
        float wagShiftY = cos(tailBone.w - distTail * 9.0) * (tailParams.x * 0.55) * tailWeight;
        sampleUV -= float2(wagShiftX, wagShiftY);
    }

    // 3. Independent Wing / Dorsal Scale Flutter (Bat-Cat wings flap, Dragon-Cat scales ripple)
    if (abs(tailParams.y) > 0.0005) {
        float2 wingCenter = tailParams.zw;
        float2 dWing = uv - wingCenter;
        float wingWeight = exp(-dot(dWing, dWing) / 0.036);
        float flapAngle = tailParams.y * wingWeight;
        float cs = cos(-flapAngle);
        float sn = sin(-flapAngle);
        float2 rotW = float2(dWing.x * cs - dWing.y * sn, dWing.x * sn + dWing.y * cs);
        sampleUV += (rotW - dWing) * wingWeight;
        sampleUV.y += tailParams.y * 0.09 * wingWeight;
    }

    // 4. Independent Alternating Front-Paw Kneading / Stepping ("Making Biscuits")
    float2 dPawL = uv - pawBones.xy;
    float pawWeightL = exp(-dot(dPawL, dPawL) / 0.0085);
    sampleUV.y += pawLifts.x * pawWeightL;
    sampleUV.x -= pawLifts.x * 0.25 * pawWeightL;

    float2 dPawR = uv - pawBones.zw;
    float pawWeightR = exp(-dot(dPawR, dPawR) / 0.0085);
    sampleUV.y += pawLifts.y * pawWeightR;
    sampleUV.x += pawLifts.y * 0.25 * pawWeightR;

    // 5. Independent Head Rotation & 2.5D Gaze Shift around Neck Pivot
    float2 headCenter = headBone.xy;
    float2 dHead = uv - headCenter;
    float headR = max(headBone.z, 0.08);
    float headWeight = exp(-dot(dHead, dHead) / (headR * headR * 1.15));
    // Smoothly attenuate below neck so torso remains naturally connected
    float neckMask = smoothstep(headCenter.y + 0.22, headCenter.y + 0.04, uv.y);
    float hw = clamp(headWeight * neckMask, 0.0, 1.0);

    float angle = -headBone.w * hw;
    float c = cos(angle);
    float s = sin(angle);
    float2 neckPivot = float2(headCenter.x, headCenter.y + 0.11);
    float2 relNeck = sampleUV - neckPivot;
    float2 rotatedHead = float2(relNeck.x * c - relNeck.y * s, relNeck.x * s + relNeck.y * c) + neckPivot;
    sampleUV = mix(sampleUV, rotatedHead - headShift.xy, hw);

    // 6. Independent Perky Ear Twitching (localized to upper ear crowns)
    if (abs(headShift.z) > 0.0005) {
        float earMaskY = smoothstep(headCenter.y + 0.02, headCenter.y - 0.14, uv.y);
        float earMaskX = exp(-pow(uv.x - headCenter.x, 2.0) / 0.045);
        float ew = earMaskY * earMaskX;
        float sideSign = (uv.x < headCenter.x) ? -1.0 : 1.0;
        sampleUV.x -= sideSign * headShift.z * ew;
        sampleUV.y += abs(headShift.z) * 0.65 * ew;
    }

    return float2(sampleUV.x * w, sampleUV.y * h);
}
