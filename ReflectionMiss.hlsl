#include "Common.hlsl"


cbuffer data : register(b0)
{
    float M;
    float NUMBER_OF_INTERVALS;
    float LAST_COMPONENT_MULT;
}

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

float f(float w, float M, float b)
{
    return pow(1.0f - w * w * (1.0f - 2*M / b * w), -0.5f);
}


//static const int NUMBER_OF_INTERVALS = 9; //must be multiple of 3
double fSimpson(float M, float b, float lowerBound, float upperBound)
{
    double n = (double) NUMBER_OF_INTERVALS;
    double lb = (double) lowerBound;
    double ub = (double) upperBound;
    double h = (ub - lb) / n;
    
    double sum = 0.0;
    
    double simpsonMult = (3.0 * h / 8.0);
    
    sum += simpsonMult * f(lb, M, b);
    for (int i = 1; i < n-2; i = i + 3)
    {
        sum += simpsonMult * 3.0 * (double)f(lb + i * h, M, b);
        sum += simpsonMult * 3.0 * (double)f(lb + (i + 1) * h, M, b);
        sum += simpsonMult * 2.0 * (double) f(lb + (i + 2) * h, M, b);
    }
    sum += simpsonMult * 3.0 * (double)f(lb + (n - 2) * h, M, b);
    sum += simpsonMult * (double)LAST_COMPONENT_MULT * (double) f(lb + (n - 1) * h, M, b);
    //sum += simpsonMult * f(lb + n * h, M, b);
    
    //float result = (float) (simpsonMult * sum);
    return sum;
}

double angleOfDeflection(float M, float b)
{
    return 2.0 * fSimpson(M, b, 0.0f, bisectW(M, b)) - (double) PI;
}

float3 rotateVector(float3 v, float3 axis, float phi)
{
    float cosPhi = cos(phi);
    float sinPhi = sin(phi);
    
    return v * cosPhi + cross(axis, v) * sinPhi + axis * dot(axis, v) * (1.0f - cosPhi);
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
        float integral = fSimpson(M, b, 0.0f, bisectW(M, b));
        float phi = angleOfDeflection(M, b);
        //if (2.0f * M / b < 2500.0f * 0.0001f && phi < 0.0f)
        //    phi = 0.0f;
        //phi = 4.0f * M / b;
        float3 axisOfRotation = normalize(cross(rayDir, normalize(BLACK_HOLE_POS - rayOrigin)));
    
        float3 deflectedRayDir = rotateVector(rayDir, axisOfRotation, phi);
     
        if(phi < 0.0f)
        {
            col = float3(0.0f, 0.0f, 0.0f);
        }
        else
        {
            col = skybox.SampleLevel(skyboxSampler, DirectionToSpherical(deflectedRayDir), 0).rgb;
        }
        //col = float3(fvalue*10.0f, upperBound * 0.1f, 0.0f);
        //col = float3(phi * 0.2f, -phi * 0.2f, 0.0f);
    }
    //else
    //{
    //    col = float3(1.0f, 0.0f, 1.0f);
    //}
    
    hit.colorAndDistance = float4(col, -1.0f);
    hit.normalAndIsHit = float4(0.0f, 0.0f, 0.0f, 0.0f);
    hit.rayEnergy = float4(0.0f, 0.0f, 0.0f, 0.0f);
}