/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App state to describe the current state of the brush.
*/

enum BrushPreset: Equatable {
    case solid(settings: SolidBrushStyleProvider.Settings)
    
    case sparkle(settings: SparkleBrushStyleProvider.Settings)
}

enum BrushType: Hashable, Equatable, CaseIterable, Identifiable {
    case uniform
    
    case calligraphic
    
    case sparkle
    
    var id: Self { return self }
    
    var label: String {
        switch self {
        case .calligraphic: return "Calligraphic"
        case .uniform: return "Uniform"
        case .sparkle: return "Sparkle"
        }
    }
}

@Observable
class BrushState {
    /// Type of brush being used.
    var brushType: BrushType = .uniform
    
    /// Style settings for the uniform brush type.
    var uniformStyleSettings = SolidBrushStyleProvider.Settings(thicknessType: .uniform)
    
    /// Style settings for the calligraphic brush type.
    var calligraphicStyleSettings = SolidBrushStyleProvider.Settings(thicknessType: .calligraphic())
    
    /// Style settings for the sparkle brush type.
    var sparkleStyleSettings = SparkleBrushStyleProvider.Settings()
    
    init() {}
    
    init(preset: BrushPreset) { apply(preset: preset) }
    
    var asPreset: BrushPreset {
        switch brushType {
        case .uniform: .solid(settings: uniformStyleSettings)
        case .calligraphic: .solid(settings: calligraphicStyleSettings)
        case .sparkle: .sparkle(settings: sparkleStyleSettings)
        }
    }
    
    func apply(preset: BrushPreset) {
        switch preset {
        case let .solid(settings):
            switch settings.thicknessType {
            case .uniform:
                brushType = .uniform
                uniformStyleSettings = settings
            case .calligraphic(_, _, _):
                brushType = .calligraphic
                calligraphicStyleSettings = settings
            }
        case let .sparkle(settings):
            brushType = .sparkle
            sparkleStyleSettings = settings
        }
    }
}
