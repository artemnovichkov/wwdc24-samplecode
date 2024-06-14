/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structure that returns cycling, golfing, running, and swimming workout compositions.
*/

import HealthKit
import WorkoutKit

struct WorkoutStore {
    static func createCyclingCustomWorkout() -> CustomWorkout {
        // Warmup step.
        let warmupStep = WorkoutStep()
        
        // Block 1.
        let block1 = cyclingBlockOne()
        
        // Block 2.
        let block2 = cyclingBlockTwo()

        // Cooldown step.
        let cooldownStep = WorkoutStep(goal: .time(5, .minutes))
        
        return CustomWorkout(activity: .cycling,
                             location: .outdoor,
                             displayName: "My Workout",
                             warmup: warmupStep,
                             blocks: [block1, block2],
                             cooldown: cooldownStep)
    }
    
    static func cyclingBlockOne() -> IntervalBlock {
        // Work step 1.
        var workStep1 = IntervalStep(.work)
        workStep1.step.goal = .distance(2, .miles)
        workStep1.step.alert = .speed(10, unit: .milesPerHour, metric: .current)

        // Recovery step.
        var recoveryStep1 = IntervalStep(.recovery)
        recoveryStep1.step.goal = .distance(0.5, .miles)
        recoveryStep1.step.alert = .heartRate(zone: 1)
        
        return IntervalBlock(steps: [workStep1, recoveryStep1],
                             iterations: 4)
    }
    
    static func cyclingBlockTwo() -> IntervalBlock {
        // Work step 2.
        var workStep2 = IntervalStep(.work)
        workStep2.step.goal = .time(2, .minutes)
        workStep2.step.alert = .power(250...275, unit: .watts)

        // Recovery step.
        var recoveryStep2 = IntervalStep(.recovery)
        recoveryStep2.step.goal = .time(30, .seconds)
        recoveryStep2.step.alert = .heartRate(zone: 1)
        
        // Block with two iterations.
        return IntervalBlock(steps: [workStep2, recoveryStep2],
                             iterations: 2)
    }
    
    static func createGolfWorkout() -> SingleGoalWorkout {
        SingleGoalWorkout(activity: .golf,
                          goal: .time(1, .hours))
    }
    
    static func createRunningCustomWorkout() -> CustomWorkout {
        let warmupStep = WorkoutStep(goal: .time(10, .minutes))
        let cooldownStep = WorkoutStep(goal: .time(10, .minutes))
        
        var recoveryStep = IntervalStep(.recovery)
        recoveryStep.step.goal = .distance(2, .miles)
        recoveryStep.step.alert = .speed(10...12, unit: .milesPerHour, metric: .current)
        
        var tempoStep = IntervalStep(.work)
        tempoStep.step.goal = .distance(3, .miles)
        tempoStep.step.alert = .speed(10...15, unit: .milesPerHour, metric: .current)
        
        var block = IntervalBlock()
        
        block.steps = [
            recoveryStep,
            tempoStep,
            tempoStep,
            recoveryStep
        ]
        block.iterations = 4
        
        return CustomWorkout(activity: .running,
                             location: .outdoor,
                             displayName: "New Running Workout",
                             warmup: warmupStep,
                             blocks: [block],
                             cooldown: cooldownStep)
    }
    
    static func createPoolSwimmingCustomWorkout() -> CustomWorkout {
        // Warmup step.
        let warmupStep = WorkoutStep(goal: .distance(200, .meters), displayName: "Kickswim")
        
        // Distance-with-time goal.
        let distance: Measurement<UnitLength> = Measurement(value: 100, unit: .meters)
        let time: Measurement<UnitDuration> = Measurement(value: 1, unit: .minutes)
        let distanceWithTime: WorkoutGoal = .poolSwimDistanceWithTime(distance, time)

        // Freestyle step.
        var freestyleStep = IntervalStep(.work)
        freestyleStep.step.goal = distanceWithTime
        freestyleStep.step.displayName = "Freestyle"
        
        // Backstroke step.
        var backstrokeStep = IntervalStep(.work)
        backstrokeStep.step.goal = distanceWithTime
        backstrokeStep.step.displayName = "Backstroke"
        
        // Recovery step.
        var recoveryStep = IntervalStep(.recovery)
        recoveryStep.step.goal = .time(1, .minutes)
        
        // Block with three iterations.
        let block = IntervalBlock(steps: [freestyleStep, backstrokeStep, freestyleStep, backstrokeStep, recoveryStep], iterations: 3)
        
        // Cooldown step.
        let cooldownStep = WorkoutStep(goal: .distance(200, .meters), displayName: "Easy swim")
        
        return CustomWorkout(activity: .swimming,
                             displayName: "Swim Workout",
                             warmup: warmupStep,
                             blocks: [block, block],
                             cooldown: cooldownStep)
    }
}

