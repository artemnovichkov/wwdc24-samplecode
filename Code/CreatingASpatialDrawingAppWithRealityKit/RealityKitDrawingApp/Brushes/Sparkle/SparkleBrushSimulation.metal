/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A compute kernel written in Metal Shading Language to simulate the particles in a Sparkle brush stroke, 
  and also to populate the mesh of a sparkle brush with the result of the simulation.
*/

#include <metal_stdlib>

#include "SparkleBrushVertex.h"

using namespace metal;

[[kernel]]
void sparkleBrushPopulate(device const SparkleBrushParticle *particles [[buffer(0)]],
                          device SparkleBrushVertex *output [[buffer(1)]],
                          constant const uint32_t &particleCount [[buffer(2)]],
                          uint particleIdx [[thread_position_in_grid]])
{
    if (particleIdx >= particleCount) {
        return;
    }
    
    SparkleBrushParticle particle = particles[particleIdx];
    
    const uint startIndex = particleIdx * 4;
    output[startIndex + 0] = SparkleBrushVertex { .attributes = particle.attributes, .uv = { 0, 0 }};
    output[startIndex + 1] = SparkleBrushVertex { .attributes = particle.attributes, .uv = { 0, 1 }};
    output[startIndex + 2] = SparkleBrushVertex { .attributes = particle.attributes, .uv = { 1, 1 }};
    output[startIndex + 3] = SparkleBrushVertex { .attributes = particle.attributes, .uv = { 1, 0 }};
}

[[kernel]]
void sparkleBrushSimulate(device const SparkleBrushParticle *particles [[buffer(0)]],
                          device SparkleBrushParticle *output [[buffer(1)]],
                          constant SparkleBrushSimulationParams &params [[buffer(2)]],
                          uint particleIdx [[thread_position_in_grid]])
{
    if (particleIdx >= params.particleCount) {
        return;
    }
    
    SparkleBrushParticle particle = particles[particleIdx];

    const float speed2 = length_squared(particle.velocity);
    const float dragForce = -speed2 * (params.dragCoefficient * params.deltaTime);
    const float speed = sqrt(speed2);
    const float newSpeed = max(0.f, speed + dragForce);
    
    if (min(newSpeed, speed) > 0.0001) {
        particle.velocity = particle.velocity / speed * newSpeed;
    } else {
        particle.velocity = 0;
    }
    particle.attributes.position += particle.velocity * params.deltaTime;

    // Write to output.
    output[particleIdx] = particle;
}

