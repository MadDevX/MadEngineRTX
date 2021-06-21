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
    return 1.0f - w2 + 2.0f * M / b * w2 * w;
}

float vanishingFDerivative(float w, float M, float b)
{
    return (-2.0f + 6.0f * M / b * w) * w;
}

float newtonW(float w0, float M, float b, int it, float eps)
{
    float w = w0;
    int i = 0;
    while (abs(vanishingF(w, M, b)) > eps && i < it)
    {
        w = w - vanishingF(w, M, b) / vanishingFDerivative(w, M, b);
    }
    return w;

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

//float w1(double M, double b)
//{
//    double b2 = b * b;
//    double b3 = b2 * b;
//    double b4 = b3 * b;
//    double M2 = M * M;
//    double M4 = M2 * M2;
    
//    double weirdRoot = pow((float) (b3 - 54.0 * b * M2 + 6.0 * b * M * (double) sqrt((float) (-3.0 * b2 + 81.0 * M2))), 1.0f / 3.0f);
    
//    return (b + (b2 / weirdRoot) + weirdRoot) / (6.0f * M);
//}

//float w1(float M, float b)
//{
//    double dM = (double) M;
//    double db = (double) b;
//    double b2 = db * db;
//    double b3 = b2 * db;
//    double b4 = b2 * b2;
    
//    double M2 = dM * dM;
//    double M4 = M2 * M2;
    
//    double expr = (b3 - 54.0 * db * M2 + 6.0 * dM * db * (double) sqrt((float) (81.0 * M2 - 3.0 * b2)));
//    double auxExpr = (double) pow((float) expr, 1.0f / 3.0f);
    
//    double res = (db + (b2 / auxExpr) + auxExpr) / (6.0 * dM);
//    return res;
//}

float f(float w, float M, float b)
{
    return pow(1.0f - w * w * (1.0f - 2*M / b * w), -0.5f);
}


static const int NUMBER_OF_INTERVALS = 9; //must be multiple of 3
float fSimpson(float M, float b, float lowerBound, float upperBound)
{
    double n = (double)NUMBER_OF_INTERVALS;
    double lb = (double)lowerBound;
    double ub = (double)upperBound;
    double h = (ub - lb) / n;
    
    double sum = 0.0f;
    
    sum += f(lb, M, b);
    for (int i = 1; i < n-2; i = i + 3)
    {
        sum += 3.0f * f(lb + i * h, M, b);
        sum += 3.0f * f(lb + (i + 1) * h, M, b);
        sum += 2.0f * f(lb + (i + 2) * h, M, b);
    }
    sum += 3.0f * f(lb + (n - 2) * h, M, b);
    sum += 3.0f * f(lb + (n - 1) * h, M, b);
    sum += f(lb + n * h, M, b);
    
    return (float)((3.0 * h / 8.0) * sum);
}



float angleOfDeflection(float M, float b)
{
    return 2.0f * fSimpson(M, b, 0.0f, w1(M, b)) - PI;
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
    
    float M = 1000.0f; //TODO: change dynamically
    float b = distanceToBlackHole(rayOrigin, rayDir);
    float3 col = float3(0.0f, 0.0f, 0.0f);
    
    if(b * b > 27.0f * M)
    {
        float upperBound = w1(M, b);
        float phi = angleOfDeflection(M, b);
        //phi = 4.0f * M / b;
        float3 axisOfRotation = cross(rayDir, normalize(BLACK_HOLE_POS - rayOrigin));
    
        float3 deflectedRayDir = rotateVector(rayDir, axisOfRotation, phi);
     
        col = skybox.SampleLevel(skyboxSampler, DirectionToSpherical(deflectedRayDir), 0).rgb;
        //col = float3(upperBound * 0.1f, 0.0f, 0.0f);
    }
    
    hit.colorAndDistance = float4(col, -1.0f);
    hit.normalAndIsHit = float4(0.0f, 0.0f, 0.0f, 0.0f);
    hit.rayEnergy = float4(0.0f, 0.0f, 0.0f, 0.0f);
}