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

// Weather over the Sunroom wall, composited as premultiplied watercolor light.
[[ stitchable ]] half4 sunroomAmbient(float2 position, half4 source, float4 bounds,
                                     float time, float rain, float sunlight, float dusk) {
    float2 uv = (position - bounds.xy) / max(bounds.zw, float2(1.0));
    float wall = 1.0 - smoothstep(0.42, 0.56, uv.y);
    float windowMask = smoothstep(0.14, 0.16, uv.x) * (1.0 - smoothstep(0.84, 0.86, uv.x))
        * smoothstep(0.06, 0.08, uv.y) * (1.0 - smoothstep(0.42, 0.44, uv.y));

    // Match SunroomLight.runPerRise in SwiftUI: light moves right as screen Y increases.
    float beamX = uv.x - 0.64 * (uv.y - 0.06);
    float paneDistance = min(abs(beamX - 0.25), abs(beamX - 0.43));
    float beam = 1.0 - smoothstep(0.035, 0.085, paneDistance);
    float glow = sunlight * beam * smoothstep(0.04, 0.10, uv.y)
        * (1.0 - smoothstep(0.38, 0.64, uv.y)) * 0.12;

    // Grid coordinates drift continuously with the particles. Each cell owns one soft mote.
    float2 dustGrid = uv * float2(21.0, 17.0) + float2(time * 0.29, -time * 0.20);
    float2 dustCell = floor(dustGrid);
    float dustSeed = paperHash(dustCell);
    float2 dustCenter = 0.25 + 0.50 * float2(dustSeed, paperHash(dustCell + 37.0));
    float mote = (1.0 - smoothstep(0.010, 0.070, length(fract(dustGrid) - dustCenter)))
        * smoothstep(0.50, 0.90, dustSeed);
    glow += mote * beam * sunlight * wall * 0.45;

    // Glass streaks fall in the window opening and remain behind the front of the room.
    float column = floor(uv.x * 49.0);
    float dropSeed = paperHash(float2(column, 9.0));
    float dropY = fract(uv.y * 2.8 - time * (0.31 + dropSeed * 0.24) + dropSeed);
    float dropX = abs(fract(uv.x * 49.0 + dropY * 0.12) - 0.5);
    float streak = (1.0 - smoothstep(0.022, 0.105, dropX))
        * smoothstep(0.58, 0.72, dropY) * (1.0 - smoothstep(0.74 + dropSeed * 0.16, 0.96, dropY));
    float wet = rain * windowMask * streak * 0.53;

    // Light cloth at the window edge. The bottom moves farther than the pinned top.
    float curtainY = smoothstep(0.06, 0.44, uv.y);
    float sway = sin(time * 1.3 + uv.y * 4.9) * curtainY * (0.008 + rain * 0.004);
    float curtainX = uv.x - sway;
    float folds = 0.55 + 0.45 * sin(curtainX * 220.0 + uv.y * 5.0);
    float drape = max(1.0 - smoothstep(0.18, 0.24, curtainX), smoothstep(0.76, 0.82, curtainX));
    float curtain = drape * windowMask * (1.0 - smoothstep(0.16, 0.44, uv.y)) * (0.09 + folds * 0.11);
    curtain *= 0.8 + 0.2 * paperHash(floor(position));

    float lampStrength = smoothstep(0.20, 0.80, max(rain, dusk));
    float2 leftLamp = (uv - float2(0.22, 0.71)) / float2(0.19, 0.24);
    float2 rightLamp = (uv - float2(0.78, 0.75)) / float2(0.17, 0.23);
    float lamp = lampStrength * smoothstep(0.40, 0.62, uv.y)
        * (0.14 * exp(-2.0 * dot(leftLamp, leftLamp)) + 0.10 * exp(-2.0 * dot(rightLamp, rightLamp)));

    float3 lightColor = mix(float3(1.0, 0.96, 0.8), float3(1.0, 0.77, 0.47), dusk);
    float3 color = lightColor * glow;
    float alpha = glow;
    color = float3(0.73, 0.87, 0.93) * wet + color * (1.0 - wet);
    alpha = wet + alpha * (1.0 - wet);
    color = float3(0.93, 0.85, 0.71) * curtain + color * (1.0 - curtain);
    alpha = curtain + alpha * (1.0 - curtain);
    color = float3(1.0, 0.73, 0.37) * lamp + color * (1.0 - lamp);
    alpha = lamp + alpha * (1.0 - lamp);
    return half4(half3(color), half(alpha)) * source.a;
}
