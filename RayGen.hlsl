#include "Common.hlsl"

// Raytracing output texture, accessed as a UAV
RWTexture2D< float4 > gOutput : register(u0);

// Raytracing acceleration structure, accessed as a SRV
RaytracingAccelerationStructure SceneBVH : register(t0);

// #DXR Extra: Perspective Camera
cbuffer CameraParams : register(b0)
{
    float4x4 view;
    float4x4 projection;
    float4x4 viewI;
    float4x4 projectionI;
}

#define SAMPLE_COUNT 4

[shader("raygeneration")] 
void RayGen() {
	// Initialize the ray payload
	HitInfo payload;
    payload.colorAndDistance = float4(0.0f, 0.0f, 0.0f, 0.0f);
    float2 offsets[4];
    int i = 0;
    offsets[0] = float2(0.25f, 0.25f);
    offsets[1] = float2(0.75f, 0.25f);
    offsets[2] = float2(0.25f, 0.75f);
    offsets[3] = float2(0.75f, 0.75f);

	// Get the location within the dispatched 2D grid of work items
	// (often maps to pixels, so this could represent a pixel coordinate).
	uint2 launchIndex = DispatchRaysIndex().xy;
	
	float2 dims = float2(DispatchRaysDimensions().xy);
	
    float3 finalColor = float3(0.0f, 0.0f, 0.0f);
	
    for (i = 0; i < SAMPLE_COUNT; i++)
    {
	
        float2 d = (((launchIndex.xy + offsets[i]) / dims.xy) * 2.0f - 1.0f);
	
		// #DXR Extra: Perspective Camera
		float aspectRatio = dims.x / dims.y;
        float3 currentRayEnergy = float3(1.0f, 1.0f, 1.0f);
        float3 resultColor = float3(0.0f, 0.0f, 0.0f);
        float3 currentPosition = mul(viewI, float4(0.0f, 0.0f, 0.0f, 1.0f));;
        float4 target = mul(projectionI, float4(d.x, -d.y, 1.0f, 1.0f));
        float3 currentDirection = mul(viewI, float4(target.xyz, 0.0f));
        float3 currentNormal = (0.0f, 0.0f, 0.0f);
        float currentMinTMult = 1.0f;
    
        ReflectionHitInfo reflectionPayload;
        int lastValidReflection = 0;
        int j;
        RayDesc ray;
        for (j = 0; j < NUM_REFLECTIONS; j++)
        {
        // Fire a reflection ray.
            ray.Origin = currentPosition;
            ray.Direction = currentDirection;
            ray.TMin = clamp(MIN_SECONDARY_RAY_T * currentMinTMult, MIN_SECONDARY_RAY_T, MIN_SECONDARY_RAY_T_MAX_VALUE);
            ray.TMax = MAX_RAY_T;
    
        // Initialize the ray payload
            reflectionPayload.colorAndDistance = float4(0.0f, 0.0f, 0.0f, 0.0f);
            reflectionPayload.normalAndIsHit = float4(0.0f, 0.0f, 0.0f, 0.0f);
            reflectionPayload.rayEnergy = float4(currentRayEnergy, 1.0f);
    
        // Trace the ray
            TraceRay(
            SceneBVH, // Acceleration structure
            DEFAULT_RAY_FLAG, // Flags 
            0xFF, // Instance inclusion mask: include all
            2, // Hit group offset : reflection hit group
            0, // SBT offset
            2, // Index of the miss shader: reflection miss shader
            ray, // Ray information to trace
            reflectionPayload); // Payload
        
            float hitMult = saturate(reflectionPayload.normalAndIsHit.w);
            float shouldNotAdd = (hitMult + saturate(1.0f - j) * (1.0f - hitMult));
            resultColor += currentRayEnergy.rgb * reflectionPayload.colorAndDistance.rgb * (SKY_INTENSITY - (SKY_INTENSITY - 1.0f) * shouldNotAdd);
            currentRayEnergy.rgb = reflectionPayload.rayEnergy.rgb;
        
            lastValidReflection = j;
            if (reflectionPayload.normalAndIsHit.w == 0.0f)
            {
                break;
            }
            else
            {
                currentMinTMult = reflectionPayload.normalAndIsHit.w;
            }
        
            currentPosition += currentDirection * reflectionPayload.colorAndDistance.w;
            currentNormal = reflectionPayload.normalAndIsHit.xyz;
            currentDirection = reflect(currentDirection, currentNormal);
        
        }
		
		
        float mult = 1.0f / (i + 1.0f);
        finalColor = mult * resultColor + (1.0f - mult) * finalColor;
    }
	
	gOutput[launchIndex] = float4(finalColor, 1.f);
}
