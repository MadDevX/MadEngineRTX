#include "Common.hlsl"

Texture2D skybox : register(t0);
SamplerState skyboxSampler : register(s0);

[shader("miss")]
void ReflectionMiss(inout ReflectionHitInfo hit : SV_RayPayload)
{
    float3 rayDir = normalize(WorldRayDirection());
    
    float3 col = skybox.SampleLevel(skyboxSampler, DirectionToSpherical(rayDir), 0).rgb;
    
    hit.colorAndDistance = float4(col, -1.0f);
    hit.normalAndIsHit = float4(0.0f, 0.0f, 0.0f, 0.0f);
}