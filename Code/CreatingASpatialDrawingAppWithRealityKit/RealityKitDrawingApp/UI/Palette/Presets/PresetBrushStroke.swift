/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Describes a path for a mesh to be drawn for the `PresetBrushView`.
*/

struct PresetBrushStroke {
    static let samples: [SIMD3<Float>] = {
        let points: [SIMD2<Float>] = [
            [80, 273],
            [203, 152],
            [236, 125],
            [264, 106],
            [283, 100],
            [295, 104],
            [300, 107],
            [307, 115],
            [309, 128],
            [304, 144],
            [296, 158],
            [260, 206],
            [210, 264],
            [181, 303],
            [174, 325],
            [175, 344],
            [186, 355],
            [200, 358],
            [216, 352],
            [234, 340],
            [251, 326],
            [322, 263],
            [344, 251],
            [357, 250],
            [364, 254],
            [370, 263],
            [368, 275],
            [361, 290],
            [330, 347],
            [328, 365],
            [336, 372],
            [345, 374],
            [356, 369],
            [369, 359],
            [387, 344]
        ]

        let extents: SIMD2<Float> = [512, 512]
        let halfExtents = extents / 2
        
        let center: SIMD2<Float> = [256, 256]

        return points.map { point in
            var framedPoint = SIMD3<Float>((point - center) / halfExtents, 0)
            framedPoint.y *= -1
            return framedPoint
        }
    }()
}
