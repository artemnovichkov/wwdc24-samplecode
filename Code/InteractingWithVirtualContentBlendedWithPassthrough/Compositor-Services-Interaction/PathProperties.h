/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders and Swift/ObjC source.
*/

#ifndef PathProperties_h
#define PathProperties_h

typedef struct
{
    simd_float3 color;
    float opacity;
    float radius;
    int verticesPerSegment;
} PathProperties;

typedef struct
{
    simd_float3 position;
    simd_float3 cameraPosition;
} PathPoint;

typedef NS_ENUM(EnumBackingType, PathPropertiesBufferIndex)
{
    PathPropertiesBufferIndexPositions = BufferIndexCount,
    PathPropertiesBufferIndexParameters,
};

typedef NS_ENUM(EnumBackingType, PathPropertiesTextureIndex)
{
    PathPropertiesTextureIndexColor = 0,
};

#endif /* PathProperties_h */
