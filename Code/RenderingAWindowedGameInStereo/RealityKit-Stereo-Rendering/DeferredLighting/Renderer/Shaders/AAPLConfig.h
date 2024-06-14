/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header that defines the preprocessor conditional values for controlling the app's configuration.
*/

// Must account for simulator target in both application Objective-C code and Metal
// shader code, so use `__APPLE_EMBEDDED_SIMULATOR__` to check if building for
// simulator target in Metal shader code.
#if TARGET_OS_SIMULATOR || defined(__APPLE_EMBEDDED_SIMULATOR__)
#define TARGET_OS_SIMULATOR 1
#endif

// When enabled, writes depth values in eye space to the g-buffer depth
// component. This allows the deferred pass to calculate the eye space fragment
// position more easily to apply lighting. When disabled, the screen
// depth is written to the g-buffer depth component and an extra inverse
// transform from screen space to eye space is necessary to calculate lighting
// contributions in the deferred pass.
#define USE_EYE_DEPTH              1

// When enabled, uses the stencil buffer to avoid execution of lighting
// calculations on fragments that don't intersect with a 3D light volume.
// When disabled, all fragments covered by a light in screen space will have
// lighting calculations executed. This means that considerably more fragments
// will have expensive lighting calculations executed than is actually
// necessary.
#define LIGHT_STENCIL_CULLING           1
