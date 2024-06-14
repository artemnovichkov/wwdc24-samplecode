/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Metal shaders used to render shadow maps.
*/
// Include the header shared between this Metal shader code and the C code that executes the Metal API commands.
#include "AAPLShaderTypes.h"

struct ShadowOutput
{
    float4 position [[position]];
};

vertex ShadowOutput shadow_vertex(const device AAPLShadowVertex * positions [[ buffer(AAPLBufferIndexMeshPositions) ]],
                                  constant     AAPLFrameData    & frameData [[ buffer(AAPLBufferFrameData) ]],
                                  uint                            vid       [[ vertex_id ]])
{
    ShadowOutput out;

    // Add the vertex position to the fairy position and project to clip-space.
    out.position = frameData.shadow_mvp_matrix * float4(positions[vid].position, 1.0);

    return out;
}
