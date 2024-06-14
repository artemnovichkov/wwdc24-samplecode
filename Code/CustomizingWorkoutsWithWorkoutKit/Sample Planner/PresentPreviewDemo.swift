/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The workout composition preview.
*/

import SwiftUI
import WorkoutKit

struct PresentPreviewDemo: View {
    private let cyclingWorkoutPlan: WorkoutPlan
    @State var showPreview: Bool = false
    
    init() {
        cyclingWorkoutPlan = WorkoutPlan(.custom(WorkoutStore.createCyclingCustomWorkout()))
    }
    
    var body: some View {
        Button("Present Cycling Workout Preview") {
            showPreview.toggle()
        }
        .workoutPreview(cyclingWorkoutPlan, isPresented: $showPreview)
    }
}

struct PresentPreviewDemo_Previews: PreviewProvider {
    static var previews: some View {
        PresentPreviewDemo()
    }
}

