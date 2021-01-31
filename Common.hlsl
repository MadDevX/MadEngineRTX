// Hit information, aka ray payload
// This sample only carries a shading color and hit distance.
// Note that the payload should be kept as small as possible,
// and that its size must be declared in the corresponding
// D3D12_RAYTRACING_SHADER_CONFIG pipeline subobject.
struct HitInfo
{
  float4 colorAndDistance;
};

// Attributes output by the raytracing when hitting a surface,
// here the barycentric coordinates
struct Attributes
{
  float2 bary;
};

struct ShadowHitInfo
{
    bool isHit;
};

struct ReflectionHitInfo
{
    float4 colorAndDistance;
    //Currently "IsHit" is also used to store triangle side length (assumed that all triangle sides have length of the same order of magnitude)
    //This may be used as a multiplier for minRayT of reflected rays in iterative approach
    float4 normalAndIsHit; 
};

struct STriVertex
{
    float3 vertex;
    float4 color;
};

static const float PI = 3.14159265f;

static const float3 LIGHT_POS = float3(2.0f, 0.25f, 2.5f) * 50000.0f;
static const float3 LIGHT_COL = float3(1.0f, 1.0f, 1.0f);

static const float3 PLANE_COL = float3(0.7f, 0.7f, 0.3f);

static const float AMBIENT_FACTOR = 0.3f;

static const float MIX_FACTOR = 0.1f;

static const float3 SKY_COL = float3(0.0f, 0.2f, 0.7f);

static const float MAX_RAY_T = 100000.0f;

static const float MIN_SECONDARY_RAY_T = 0.00005f;
static const float MIN_SECONDARY_RAY_T_MAX_VALUE = 0.01f;
// TMin = 0.000001f - at this value artifacts are starting to be visible
// TMin = 0.0f - artifacts clearly visible, image is very noisy
// TMin = 0.01f - inside of geometries / interlapping faces generate visible "pass through" bands near intersections
// TMin = 0.00001f - for set resolution (1280x720) virtually no "pass through" bands visible with no visible artifacts

// Behaviour also changes for triangle primitives of different scales - for large triangles default minT may prove too small, causing geometry to intersect with itself
// Thus, multipliers are required to minimize visible artifacts - but even multiplied minT must be less than a set value, otherwise interaction of large geometry with small geometry 
// causes pass-through bands visible in specular reflections (scale mismatch)

#define NUM_REFLECTIONS 10

#define DEFAULT_RAY_FLAG RAY_FLAG_CULL_FRONT_FACING_TRIANGLES

float2 DirectionToSpherical(float3 dir)
{
    float theta = acos(dir.y) / (PI);
    float phi = atan2(dir.x, dir.z) / (PI * 2.0f) + 0.5f;
    return float2(phi, theta);
}