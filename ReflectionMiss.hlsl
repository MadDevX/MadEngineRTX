#include "Common.hlsl"

float distanceToBlackHole(float3 rayOrigin, float3 rayDirection)
{
    float3 toBlackHole = BLACK_HOLE_POS - rayOrigin;
    float projectionLength = dot(toBlackHole, rayDirection);
    float3 rayPathClosestPoint = rayDirection * projectionLength;
    float3 bVector = toBlackHole - rayPathClosestPoint;
    return length(bVector);
}

float vanishingF(float w, float M, float b)
{
    float w2 = w * w;
    return 1.0f - w2 + w2 * w * 2.0f * M / b;
}

float vanishingFDerivative(float w, float M, float b)
{
    return (-2.0f + 6.0f * M / b * w) * w;
}


float newtonW(float M, float b)
{
    float w = b / (3.0f * M);
    int i = 0;
    while (abs(vanishingF(w, M, b)) > EPS || vanishingF(w, M, b) < 0.0f)
    {
        w = w - vanishingF(w, M, b) / vanishingFDerivative(w, M, b);
    }
    return w;

}

float bisectW(float M, float b)
{
    float l = 0.0f;
    float r = b / (6.0f * M);
    float m = (l + r) * 0.5f;
    float lf = vanishingF(l, M, b);
    float rf = vanishingF(r, M, b);
    float mf = vanishingF(m, M, b);
    int i = 0;
    
    while (abs(r-l) > EPS)
    {
        if(mf * lf > 0.0f)
        {
            l = m;
            lf = mf;
        }
        else if (mf * rf > 0.0f)
        {
            r = m;
            rf = mf;
        }
        else
        {
            return 0.0f;
        }
        m = (l + r) * 0.5f;
        mf = vanishingF(m, M, b);
    }
    return l;
}

float w1(float M, float b)
{
    float b2 = b * b;
    float b3 = b2 * b;
    float b4 = b3 * b;
    float M2 = M * M;
    float M4 = M2 * M2;
    
    float weirdRoot = pow(-b3 + 54.0f * b * M2 + 6.0f * b * M * sqrt(-3.0 * b2 + 81.0 * M2), 1.0f / 3.0f);
    
    return (-b + (b2 / weirdRoot) + weirdRoot) / (6.0f * M);
}

float f(float w, float M, float b)
{
    return pow(1.0f - w * w * (1.0f - 2*M / b * w), -0.5f);
}


static const int NUMBER_OF_INTERVALS = 9; //must be multiple of 3
float fSimpson(float M, float b, float lowerBound, float upperBound)
{
    float n = NUMBER_OF_INTERVALS;
    float lb = lowerBound;
    float ub = upperBound;
    float h = (ub - lb) / n;
    
    float sum = 0.0f;
    
    sum += f(lb, M, b);
    for (int i = 1; i < n-2; i = i + 3)
    {
        sum += 3.0f * f(lb + i * h, M, b);
        sum += 3.0f * f(lb + (i + 1) * h, M, b);
        sum += 2.0f * f(lb + (i + 2) * h, M, b);
    }
    sum += 3.0f * f(lb + (n - 2) * h, M, b);
    sum += 3.0f * f(lb + (n - 1) * h, M, b);
    //sum += f(lb + n * h, M, b);
    
    return (3.0f * h / 8.0f) * sum;
}



float angleOfDeflection(float M, float b)
{
    return 2.0f * fSimpson(M, b, 0.0f, bisectW(M, b)) - PI;
}

float3 rotateVector(float3 v, float3 axis, float phi)
{
    float cosPhi = cos(phi);
    float sinPhi = sin(phi);
    
    return v * cosPhi + cross(axis, v) * sinPhi + axis * dot(axis, v) * (1.0f - cosPhi);
}

cbuffer data : register(b0)
{
    float M;
}

Texture2D skybox : register(t0);
SamplerState skyboxSampler : register(s0);

[shader("miss")]
void ReflectionMiss(inout ReflectionHitInfo hit : SV_RayPayload)
{
    float3 rayOrigin = WorldRayOrigin();
    float3 rayDir = normalize(WorldRayDirection());
    
    float b = distanceToBlackHole(rayOrigin, rayDir);
    float3 col = float3(0.0f, 0.0f, 0.0f);
    
    if(b * b > 27.0f * M * M)
    {
        float upperBound = bisectW(M, b);
        float fvalue = vanishingF(upperBound, M, b);
        float phi = angleOfDeflection(M, b);
        //phi = 4.0f * M / b;
        float3 axisOfRotation = normalize(cross(rayDir, normalize(BLACK_HOLE_POS - rayOrigin)));
    
        float3 deflectedRayDir = rotateVector(rayDir, axisOfRotation, phi);
     
        col = skybox.SampleLevel(skyboxSampler, DirectionToSpherical(deflectedRayDir), 0).rgb;
        //col = float3(fvalue*10.0f, upperBound * 0.1f, 0.0f);
        //col = float3(2.0f * M / b, 0.0f, 0.0f);
    }
    //else
    //{
    //    col = float3(1.0f, 0.0f, 1.0f);
    //}
    
    hit.colorAndDistance = float4(col, -1.0f);
    hit.normalAndIsHit = float4(0.0f, 0.0f, 0.0f, 0.0f);
    hit.rayEnergy = float4(0.0f, 0.0f, 0.0f, 0.0f);
}