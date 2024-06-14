/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main content view.
*/

import SwiftUI
@preconcurrency import WorkoutKit

struct SamplePlannerView: View {
    @State var authorizationState: WorkoutScheduler.AuthorizationState = .notDetermined
    @State var scheduledWorkouts: [ScheduledWorkoutPlan] = []
    
    let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            List {
                Section("Scheduled Workouts") {
                    ForEach(scheduledWorkouts, id: \.self) { scheduledWorkout in
                        if let scheduledDate = Calendar.autoupdatingCurrent.date(from: scheduledWorkout.date) {
                            VStack(alignment: .leading) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(scheduledWorkout.plan.workout.activity.displayName)
                                        
                                        let relativeDate = dateFormatter.localizedString(for: scheduledDate, relativeTo: .now)
                                        Text(relativeDate)
                                            .font(.footnote)
                                            .foregroundStyle(.gray)
                                    }
                                    if scheduledWorkout.complete {
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .fontWeight(.bold)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Request Authorization") {
                        Task {
                            authorizationState = await WorkoutScheduler.shared.requestAuthorization()
                            await update()
                        }
                    }
                    .disabled(authorizationState != .notDetermined)
                } footer: {
                    Text("Current authorization state: \(String(describing: authorizationState))")
                }
            }
            .navigationTitle("Sample Planner")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Menu {
                            scheduleMenuOptions(for: WorkoutPlan(.goal(WorkoutStore.createGolfWorkout())))
                        } label: {
                            HStack(alignment: .center) {
                                Image(systemName: "figure.golf")
                                Text("Schedule Golf")
                            }
                        }
                        
                        Menu {
                            scheduleMenuOptions(for: WorkoutPlan(.custom(WorkoutStore.createCyclingCustomWorkout())))
                        } label: {
                            HStack(alignment: .center) {
                                Image(systemName: "figure.outdoor.cycle")
                                Text("Schedule Cycling")
                            }
                        }
                        
                        Menu {
                            scheduleMenuOptions(for: WorkoutPlan(.custom(WorkoutStore.createRunningCustomWorkout())))
                        } label: {
                            HStack(alignment: .center) {
                                Image(systemName: "figure.run")
                                Text("Schedule Running")
                            }
                        }
                        
                        Menu {
                            scheduleMenuOptions(for: WorkoutPlan(.custom(WorkoutStore.createPoolSwimmingCustomWorkout())))
                        } label: {
                            HStack(alignment: .center) {
                                Image(systemName: "figure.pool.swim")
                                Text("Schedule Pool Swimming")
                            }
                        }
                    } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                    .disabled(authorizationState != .authorized)
                }
            }
        }
        .task {
            await update(force: true)
        }
        .refreshable {
            await update(force: true)
        }
    }
    
    private func schedule(workout: WorkoutPlan,
                          daysAhead: Int = 0,
                          hoursAhead: Int = 0) async {
        
        var daysAheadComponents = DateComponents()
        daysAheadComponents.day = daysAhead
        daysAheadComponents.hour = hoursAhead
        
        guard let nextDate = Calendar.autoupdatingCurrent.date(byAdding: daysAheadComponents, to: .now) else {
            return
        }
        
        let nextDateComponents = Calendar.autoupdatingCurrent.dateComponents(in: .autoupdatingCurrent, from: nextDate)
        await WorkoutScheduler.shared.schedule(workout, at: nextDateComponents)
        
        scheduledWorkouts.append(ScheduledWorkoutPlan(workout, date: nextDateComponents))
    }
    
    private func update(force: Bool = false) async {
        if force || authorizationState != .authorized {
            authorizationState = await WorkoutScheduler.shared.authorizationState
        }
        scheduledWorkouts = await WorkoutScheduler.shared.scheduledWorkouts
    }
    
    @ViewBuilder
    private func scheduleMenuOptions(for workout: WorkoutPlan) -> some View {
        Button {
            Task {
                await schedule(workout: workout, hoursAhead: 1)
            }
        } label: {
            Text("In one hour")
        }
        
        Button {
            Task {
                await schedule(workout: workout, daysAhead: 1)
            }
        } label: {
            Text("Tomorrow")
        }
        
        Button {
            Task {
                await schedule(workout: workout, daysAhead: 2)
            }
        } label: {
            Text("In 2 days")
        }
        
        Button {
            Task {
                await schedule(workout: workout, daysAhead: 3)
            }
        } label: {
            Text("In 3 days")
        }
    }
}

struct SamplePlannerView_Previews: PreviewProvider {
    static var previews: some View {
        SamplePlannerView()
    }
}
